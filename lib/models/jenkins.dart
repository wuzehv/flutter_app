import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/global.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';

import 'loading.dart';

class JenkinsModel {
  late String? id;
  final String remark;
  final String url;
  final String user;
  final String token;

  Dio? _dio;

  Dio get dio => _dio!;

  JenkinsModel({required this.remark, required this.url, required this.user, required this.token, this.id});

  Map<String, dynamic> toJson() {
    return {'id': id, 'remark': remark, 'url': url, 'user': user, 'token': token};
  }

  factory JenkinsModel.fromJson(Map<String, dynamic> json) {
    return JenkinsModel(id: json['id'], remark: json['remark'], user: json['user'], url: json['url'], token: json['token']);
  }

  @override
  String toString() {
    return 'Jenkins{id: $id, remark: $remark, url: $url, user: $user, token: $token}';
  }

  Dio _getDio() {
    if (_dio != null) {
      return _dio!;
    }
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

    String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$token'))}';
    dio.options.headers['Authorization'] = basicAuth;
    dio.options.headers['Content-Type'] = Headers.formUrlEncodedContentType;

    _dio = dio;
    return dio;
  }

  Future<List<String>> getJobList() async {
    final response = await _getDio().post('$url/api/json?tree=views[name]');
    return List<String>.from(response.data['views'].where((e) => e['_class'] != 'hudson.model.AllView').map((e) => e['name']));
  }

  Future<List<String>> getProjectList(String job) async {
    final response = await _getDio().post('$url/view/$job/api/json?tree=jobs[name]');
    return List<String>.from(response.data['jobs'].map((e) => e['name']));
  }

  Future<void> auditBuild(String opUrl) async {
    final jsonString = jsonEncode({"parameter": []});

    try {
      await _getDio().post('$url$opUrl', data: FormData.fromMap({'json': jsonString}));
      showSucc('操作成功');
    } catch (e) {
      showError('操作失败，请检查任务');
    }
  }

  Future<Map<String, dynamic>> getBuildDetail(String name, String id) async {
    try {
      final response = await _getDio().post(
        '$url/job/$name/$id/api/json?tree=actions[parameters[name,value],causes[userName]],result',
      );

      // 兼容参数和审核人顺序相反情况，目前只有shipla存在
      var idx = response.data['actions'][0]['causes'] == null ? [0, 1] : [1, 0];

      List<dynamic> res = response.data['actions'][idx[0]]['parameters']
          .map((param) => '${param['name']}: ${param['value']}')
          .toList();
      res.add('提交人: ${response.data['actions'][idx[1]]['causes'][0]['userName']}');

      // 获取当前任务是否需要审核
      Map<String, dynamic> m = {'list': res, 'id': id};
      if (response.data['result'] == null) {
        final response2 = await _getDio().post('$url/job/$name/$id/wfapi/pendingInputActions/api/json');
        if (response2.data is List && response2.data.length >= 1) {
          m['proceedUrl'] = response2.data[0]['proceedUrl'];
          m['abortUrl'] = response2.data[0]['abortUrl'];
        }
      }

      return m;
    } catch (e) {
      showError('读取失败，请检查当前构建信息');
    }

    return {'list': []};
  }

  Future<List<dynamic>?> getLogList(BuildContext context, String name) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    try {
      final response = await _getDio().post(
        '$url/job/$name/api/json?tree=builds[id,result,timestamp,actions[parameters[name,value]{,5},causes[userName]]{,2}]{,10}',
      );

      if (response.data['builds'] == null) {
        showInfo('无数据');
      }
      return response.data['builds'];
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
    } finally {
      loader.hide();
    }
    return null;
  }
}

class JenkinsProvider extends ChangeNotifier {
  List<dynamic> _items = [];

  List<dynamic> get items => _items;

  void add(JenkinsModel item) {
    if (item.id == null) {
      item.id = getRandomString(10);
    } else {
      JenkinsStore.remove(item.id!);
    }
    JenkinsStore.add(item.id!, item);

    list();
  }

  void remove(String id) {
    JenkinsStore.remove(id);
    list();
  }

  Future<void> list() async {
    _items = await JenkinsStore.list();
    notifyListeners();
  }
}

mixin JenkinsSetter<T> {
  JenkinsModel? _currentJenkins;

  T setJenkins(JenkinsModel jenkins) {
    _currentJenkins = jenkins;
    return this as T;
  }

  JenkinsModel? get currentJenkins => _currentJenkins;
}

class JenkinsJobModel {
  final String name;

  JenkinsJobModel({required this.name});
}

class JenkinsJobProvider extends ChangeNotifier with JenkinsSetter<JenkinsJobProvider> {
  List<JenkinsJobModel> jobs = [];

  Future<void> fetchJobs() async {
    if (_currentJenkins == null) return;
    final response = await _currentJenkins?.getJobList();
    jobs = response!.map((x) => JenkinsJobModel(name: x)).toList();
    notifyListeners();
  }
}

class JenkinsProjectModel {
  final String name;

  JenkinsProjectModel({required this.name});

  List<Widget> getOperation() {
    return [
      Center(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.only(top: 10.0)),
            Text('当前项目未实现', style: TextStyle(color: Colors.red)),
            Padding(padding: const EdgeInsets.only(top: 10.0)),
          ],
        ),
      ),
    ];
  }
}

class JenkinsProjectProvider extends ChangeNotifier with JenkinsSetter<JenkinsProjectProvider> {
  List<JenkinsProjectModel> projects = [];

  final Map<String, bool> _expanded = {};

  bool isExpanded(String projectName) => _expanded[projectName] ?? false;

  Future<void> fetchProjects(String job) async {
    if (_currentJenkins == null) return;
    final response = await _currentJenkins?.getProjectList(job);
    projects = response!.map((x) => JenkinsProjectModel(name: x)).toList();
    notifyListeners();
  }

  void toggleExpanded(String projectName) {
    _expanded[projectName] = !(_expanded[projectName] ?? false);
    notifyListeners();
  }

  List<Widget> getOperation(BuildContext context, String name) {
    return getInstance(context, _currentJenkins!, name).getOperation();
  }
}

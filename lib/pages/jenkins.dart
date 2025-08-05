import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';

class Jenkins {
  final String? id;
  final String remark;
  final String url;
  final String user;
  final String token;

  String? project; // 当前项目，进入某个项目时使用

  List<String>? jobs;
  List<String>? projects;
  List<dynamic>? projectBuildLog;

  Dio? _dio;

  Jenkins({required this.remark, required this.url, required this.user, required this.token, this.id, this.project});

  // 已经实现了的项目
  Set<String> buildProject = {'wms_boss_api', 'wms_new_api-php', 'wms_scm_api-php'};

  Map<String, dynamic> toJson() {
    return {'id': id, 'remark': remark, 'url': url, 'user': user, 'token': token, 'project': project};
  }

  factory Jenkins.fromJson(Map<String, dynamic> json) {
    return Jenkins(id: json['id'], remark: json['remark'], user: json['user'], url: json['url'], token: json['token']);
  }

  @override
  String toString() {
    return 'Jenkins{id: $id, remark: $remark, url: $url, user: $user, token: $token}';
  }

  Future<void> getJobList() async {
    final response = await _getDio().post('$url/api/json?tree=views[name]');
    jobs = List<String>.from(response.data['views'].where((e) => e['_class'] != 'hudson.model.AllView').map((e) => e['name']));
  }

  Future<void> getProjectList(String job) async {
    final response = await _getDio().post('$url/view/$job/api/json?tree=jobs[name]');
    projects = List<String>.from(response.data['jobs'].map((e) => e['name']));
  }

  Future<void> getProjectBuildLog(String project) async {
    this.project = project;
    final response = await _getDio().post('$url/job/$project/api/json?tree=builds[result,timestamp,id]{,15}');
    projectBuildLog = response.data['builds'];
  }

  Future<Map<String, dynamic>> getProjectBuildDetail(String id) async {
    this.project = project;
    final response = await _getDio().post(
      '$url/job/$project/$id/api/json?tree=actions[parameters[name,value],causes[userName]],result',
    );
    List<dynamic> res = response.data['actions'][0]['parameters']
        .where((param) => !['action', 'update_config', 'install_plugin', 'commit_id'].contains(param['name']))
        .map((param) => '${param['name']}: ${param['value']}')
        .toList();
    res.add('提交人: ${response.data['actions'][1]['causes'][0]['userName']}');

    // 获取当前任务是否需要审核
    Map<String, dynamic> m = {'list': res, 'id': id};
    if (response.data['result'] == null) {
      final response2 = await _getDio().post('$url/job/$project/$id/wfapi/pendingInputActions/api/json');
      if (response2.data is List && response2.data.length >= 1) {
        m['proceedUrl'] = response2.data[0]['proceedUrl'];
        m['abortUrl'] = response2.data[0]['abortUrl'];
      }
    }

    return m;
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

  Dio _getDio() {
    if (_dio != null) {
      return _dio!;
    }
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

    String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$token'))}';
    dio.options.headers['Authorization'] = basicAuth;
    dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';

    _dio = dio;
    return dio;
  }

  Future<void> quickBuild(BuildContext context, String project, String env) async {
    if (!buildProject.contains(project)) {
      showError('当前项目未实现');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      if (env == 'tra') {
        List<Future> x = [];
        for (var e in ['tra', 'ph-tra', 'la-tra', 'my-tra']) {
          x.add(
            _getDio().post(
              '$url/job/$project/buildWithParameters',
              data: FormData.fromMap({"branch": "training", "environment": e, 'inventory': 'All'}),
            ),
          );
        }
        await Future.wait(x);
      }

      if (env == 'pro') {
        List<Future> x = [];
        for (var e in ['pro', 'ph-pro', 'vn-pro', 'la-pro', 'my-pro', 'id-pro', 'sg-pro', 'sz-pro']) {
          x.add(
            _getDio().post(
              '$url/job/$project/buildWithParameters',
              data: FormData.fromMap({"branch": "master", "environment": e, 'inventory': 'All', 'approver': 'wuzehui'}),
            ),
          );
        }
        await Future.wait(x);
      }

      Navigator.of(context).pop();
      showSucc('提交成功');
    } catch (e) {
      Navigator.of(context).pop();
      showError('提交失败，请检查网络');
    }
  }
}

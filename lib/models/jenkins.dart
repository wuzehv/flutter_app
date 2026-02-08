import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/jenkins_global.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';

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

    dio.options.headers['X-J-User'] = user;
    dio.options.headers['X-J-Token'] = token;
    dio.options.headers['Content-Type'] = Headers.jsonContentType;

    _dio = dio;
    return dio;
  }

  Future<List<Map<String, dynamic>>> getJobList() async {
    final response = await _getDio().get('http://192.168.110.144:8989/open/projects');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<List<Map<String, dynamic>>> getPendingList() async {
    final response = await _getDio().get('http://192.168.110.144:8989/open/pending?user=$user');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<List<Map<String, dynamic>>> getBuildList(String project) async {
    final response = await _getDio().get('http://192.168.110.144:8989/open/builds?project=$project');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<void> proceedBuild(int id) async {
    try {
      await _getDio().post('http://192.168.110.144:8989/open/proceed?id=$id');
      showSucc('已通过');
    } catch (e) {
      showError('操作失败，请检查任务');
    }
  }

  Future<void> abortBuild(int id) async {
    try {
      await _getDio().post('http://192.168.110.144:8989/open/abort?id=$id');
      showSucc('已拒绝');
    } catch (e) {
      showError('操作失败，请检查任务');
    }
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

  Future<List<Map<String, dynamic>>?> getLogList(BuildContext context, String name) async {
    try {
      final response = await _getDio().post(
        '$url/job/$name/api/json?tree=builds[id,result,timestamp,actions[parameters[name,value]{,5},causes[userName]]{,2}]{,10}',
      );

      if (response.data['builds'] == null) {
        showInfo('无数据');
        return null;
      }

      final List<Map<String, dynamic>> result = response.data['builds'].map<Map<String, dynamic>>((project) {
        late final String param1;
        late final String param2;
        late final String user;

        switch (name) {
          case wmsUi:
          case wmsBossUi:
            param1 = project['actions'][0]['parameters'][2]['value'];
            param2 = project['actions'][0]['parameters'][1]['value'];
            user = project['actions'][1]['causes'][0]['userName'];
            break;
          case shiplaCt:
          case shiplaGo:
          case shiplaWeb:
            final idx = project['actions'][0]['causes'] == null ? [0, 1] : [1, 0];
            param1 = project['actions'][idx[0]]['parameters'][2]['value'];
            param2 = project['actions'][idx[0]]['parameters'][4]['value'];
            user = project['actions'][idx[1]]['causes'][0]['userName'];
            break;
          default:
            param1 = project['actions'][0]['parameters'][4]['value'];
            param2 = project['actions'][0]['parameters'][3]['value'];
            user = project['actions'][1]['causes'][0]['userName'];
            break;
        }

        var res = 'OTHER';
        if (project['result'] == 'SUCCESS') {
          res = 'SUCCESS';
        } else if (project['result'] == 'FAILURE' || project['result'] == 'ABORTED') {
          res = 'FAILURE';
        }

        final title = "【$param1】$param2 by $user";

        return {
          'id': project['id'].toString(),
          'title': title,
          'time': formatChatTime(DateTime.fromMillisecondsSinceEpoch(project['timestamp'], isUtc: true).toString()),
          'result': res,
        };
      }).toList();

      return result;
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
    }

    return null;
  }

  Future<void> toLogPage(BuildContext context, String name, [bool fromList = true]) async {
    // final loader = context.read<LoadingProvider>();
    // loader.show();
    // final logList = await getLogList(context, name);
    // loader.hide();
    // if (logList == null) {
    //   return;
    // }
    // fromList
    //     ? context.push('/job/project/log', extra: {'obj': this, 'name': name, 'log_list': logList})
    //     : context.pushReplacement('/job/project/log', extra: {'obj': this, 'name': name, 'log_list': logList});
  }
}

class JenkinsProvider extends ChangeNotifier {
  List<dynamic> _items = [];

  List<dynamic> get items => _items;

  late ObjectStore<JenkinsModel> _store;

  Future<void> save(JenkinsModel item) async {
    _setShared();
    item.id ??= getRandomString(10);
    await _store.save(item.id!, item);
    await list();
  }

  Future<void> remove(String id) async {
    _setShared();
    await _store.remove(id);
    await list();
  }

  Future<void> list() async {
    _setShared();
    _items = await _store.list();
    notifyListeners();
  }

  void _setShared() {
    _store = ObjectStore<JenkinsModel>(
      key: 'jenkins_map',
      fromJson: (json) => JenkinsModel.fromJson(json),
      toJson: (obj) => obj.toJson(),
    );
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
  List<Map<String, dynamic>> projectList = [];
  List<Map<String, dynamic>> pendingList = [];

  final Map<String, bool> _expanded = {};
  int _pendingApprovalCount = 0;

  bool isExpanded(String jobName) => _expanded[jobName] ?? false;

  int get pendingApprovalCount => _pendingApprovalCount;

  set pendingApprovalCount(int count) {
    _pendingApprovalCount = count;
    notifyListeners();
  }

  List<Map<String, dynamic>> get getPendingList => pendingList;

  void toggleExpanded(String jobName) {
    _expanded[jobName] = !(_expanded[jobName] ?? false);
    notifyListeners();
  }

  Future<void> fetchJobs() async {
    if (_currentJenkins == null) return;
    final response = await _currentJenkins?.getJobList();
    projectList = response!;
    jobs = response.map((x) => JenkinsJobModel(name: x['name'])).toList();
    notifyListeners();
  }

  Future<void> fetchPendingApproval() async {
    if (_currentJenkins == null) return;
    try {
      final response = await _currentJenkins?.getPendingList();
      pendingList = response!;
      pendingApprovalCount = response.length;
      notifyListeners();
    } catch (e) {
      pendingList = [];
      pendingApprovalCount = 0;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchBuildList(String project) async {
    if (_currentJenkins == null) return;
    try {
      final response = await _currentJenkins?.getBuildList(project);
      pendingList = response!;
      pendingApprovalCount = response.length;
      notifyListeners();
    } catch (e) {
      pendingList = [];
      pendingApprovalCount = 0;
      notifyListeners();
      rethrow;
    }
  }

  // 通用的审核方法，接收user, token, id作为参数
  Future<bool> executeAuditAction(String user, String token, String id, {bool approve = true}) async {
    if (_currentJenkins == null) return false;
    
    try {
      // 构造认证头
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$token'))}';
      
      // 创建临时Dio实例用于此操作
      Dio tempDio = Dio();
      tempDio.options.headers['Authorization'] = basicAuth;
      tempDio.options.headers['Content-Type'] = Headers.jsonContentType;
      
      // 根据操作类型构建URL
      String apiUrl = '${_currentJenkins!.url}$id';
      final response = await tempDio.post(apiUrl);
      
      return response.statusCode == 200;
    } catch (e) {
      print('审核操作失败: $e');
      return false;
    }
  }

  Future<void> approveAllPending() async {
    if (_currentJenkins == null) return;
    
    // 遍历所有待审核项，逐一调用审核接口
    List<Map<String, dynamic>> successfulApprovals = [];
    for (var item in pendingList) {
      bool success = await executeAuditAction(
        _currentJenkins!.user,
        _currentJenkins!.token,
        item['op_url']!,
        approve: true,
      );
      
      if (success) {
        // 如果接口调用成功，标记为成功
        successfulApprovals.add(item);
      }
    }
    
    // 从pendingList中移除已成功审核的项目
    for (var item in successfulApprovals) {
      pendingList.remove(item);
    }
    
    // 更新待审核计数
    pendingApprovalCount = pendingList.length;
    
    // 通知UI更新
    notifyListeners();
  }

  Future<void> approveSingleItem(Map<String, dynamic> item) async {
    if (_currentJenkins == null) return;

    // 调用您已有的proceedBuild方法
    await _currentJenkins!.proceedBuild(item['id']);

    // 从pendingList中移除该项目
    pendingList.remove(item);
    pendingApprovalCount = pendingList.length;
    notifyListeners();
  }

  Future<void> rejectSingleItem(Map<String, dynamic> item) async {
    if (_currentJenkins == null) return;

    // 调用您已有的abortBuild方法
    await _currentJenkins!.abortBuild(item['id']);

    // 从pendingList中移除该项目
    pendingList.remove(item);
    pendingApprovalCount = pendingList.length;
    notifyListeners();
  }
  
  // 获取当前Jenkins实例的getter
  JenkinsModel? get currentJenkins => _currentJenkins;
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

  void toggleExpanded(String projectName) {
    _expanded[projectName] = !(_expanded[projectName] ?? false);
    notifyListeners();
  }

  List<Widget> getOperation(BuildContext context, String name) {
    return getInstance(context, _currentJenkins!, name).getOperation();
  }
}

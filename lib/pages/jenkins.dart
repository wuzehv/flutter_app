import 'dart:async';
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
  String? env;

  List<String>? jobs;
  List<String>? projects;
  List<dynamic>? projectBuildLog;

  Dio? _dio;

  Jenkins({required this.remark, required this.url, required this.user, required this.token, this.id, this.project});

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

  bool checkProjectImpl(String project) {
    try {
      _canBuildProject.values.byName(_getProjectEnum(project));
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> getProjectBuildLog(String project) async {
    this.project = project;
    final response = await _getDio().post(
      '$url/job/$project/api/json?tree=builds[id,result,timestamp,actions[parameters[name,value]{3,5},causes[userName]]{,2}]{,10}',
    );
    projectBuildLog = response.data['builds'];
  }

  Future<Map<String, dynamic>> getProjectBuildDetail(String id) async {
    final response = await _getDio().post(
      '$url/job/$project/$id/api/json?tree=actions[parameters[name,value],causes[userName]],result',
    );
    List<dynamic> res = response.data['actions'][0]['parameters']
        .where((param) => !['action', 'update_config', 'commit_id'].contains(param['name']))
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

  Future<void> toProjectPage(BuildContext context, String project, String env) async {
    if (!checkProjectImpl(project)) {
      showError('当前项目未实现');
      return;
    }

    this.project = project;
    this.env = env;
    var projectEnum = _getProjectEnum(project);
    if ([
      _canBuildProject.wms_boss_api.name,
      _canBuildProject.wms_new_api_php.name,
      _canBuildProject.wms_scm_api_php.name,
    ].contains(projectEnum)) {
      Navigator.pushNamed(context, 'jenkins_build_wms_be', arguments: this);
    }
  }

  String _getProjectEnum(String project) {
    return project.replaceAll('-', '_');
  }

  Future<Map<String, dynamic>> getWmsBeDetail() async {
    var idx = 4;
    if (project?.replaceAll('-', '_') != _canBuildProject.wms_new_api_php.name) {
      idx = 2;
    }
    var envParams = env!.toLowerCase();
    try {
      final response = await _getDio().post('$url/job/$project/api/json?tree=property[parameterDefinitions[name,choices]]');
      // env
      Map<String, bool> e = {};
      for (var i in response.data['property'][idx]['parameterDefinitions'][4]['choices']) {
        if (['tra', 'pro'].contains(envParams)) {
          if (i.toString().toLowerCase().contains(envParams)) {
            e[i] = true;
          }
        } else {
          e[i] = false;
        }
      }
      // 审核人
      List<String> a = [];
      for (var i in response.data['property'][idx]['parameterDefinitions'][6]['choices']) {
        a.add(i);
      }

      return {'env': e, 'approver': a};
    } catch (e) {
      showError('读取配置失败，请检查');
    }

    return {};
  }

  Stream<(String, bool)> buildWmsBe(
    BuildContext context,
    bool isPro,
    bool installPlugin,
    List<String> inputEnv,
    String approver,
    String branch,
  ) {
    var p = installPlugin ? 'Yes' : 'No';

    final controller = StreamController<(String, bool)>();
    int remaining = inputEnv.length;

    for (var e in inputEnv) {
      _getDio()
          .post(
            '$url/job/$project/buildWithParameters',
            data: FormData.fromMap({
              "branch": branch,
              "environment": e,
              'inventory': isPro ? 'All' : 'Single',
              'approver': approver,
              'install_plugin': p,
            }),
          )
          .then((onValue) {
            controller.add((e, true));
          })
          .catchError((onError) {
            controller.add((e, false));
          })
          .whenComplete(() {
            remaining--;
            if (remaining == 0) {
              controller.close();
            }
          });
    }

    return controller.stream;
  }
}

enum _canBuildProject { wms_boss_api, wms_new_api_php, wms_scm_api_php }

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/global.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';

import '../common/loading.dart';

class CodeUpModel {
  final String url = 'https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations';
  final String orgId;
  final String token;
  final String remark;

  Dio? _dio;

  Dio get dio => _dio!;

  CodeUpModel({required this.remark, required this.orgId, required this.token});

  Map<String, dynamic> toJson() {
    return {'remark': remark, 'org_id': orgId, 'token': token};
  }

  factory CodeUpModel.fromJson(Map<String, dynamic> json) {
    return CodeUpModel(remark: json['remark'], orgId: json['org_id'], token: json['token']);
  }

  @override
  String toString() {
    return 'CodeUp{remark: $remark, org_id: $orgId, token: $token}';
  }

  Dio _getDio() {
    if (_dio != null) {
      return _dio!;
    }
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

    dio.options.headers['x-yunxiao-token'] = token;
    dio.options.headers['Content-Type'] = Headers.jsonContentType;

    _dio = dio;
    return dio;
  }

  Future<List<String>> getProjectList(int page) async {
    page = page <= 0 ? 1 : page;
    final response = await _getDio().post('$url/$orgId/repositories?orderBy=last_activity_at&perPage=10&sort=desc&page=$page');
    return List<String>.from(response.data['jobs'].map((e) => e['name']));
  }

  Future<List<String>> getProjectMrList(int projectId, String status, int page) async {
    page = page <= 0 ? 1 : page;
    final response = await _getDio().post(
      '$url/$orgId/changeRequests?projectIds=$projectId?orderBy=updated_at&state=$status&perPage=10&sort=desc&page=$page',
    );
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
}

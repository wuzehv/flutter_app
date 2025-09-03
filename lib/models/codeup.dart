import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';

import '../common/loading.dart';

const mrStatusOpened = 'opened';
const mrStatusMerged = 'merged';
const mrStatusClosed = 'closed';

class CodeUpModel {
  final String url = 'https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations';
  final String orgId;
  final String token;
  final String remark;

  late List<Map<String, dynamic>> projectList;
  late List<Map<String, dynamic>> projectMrList;
  late String curProjectName;
  late int curProjectId;

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

  Future<List<Map<String, dynamic>>> getProjectList(BuildContext context, int page) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    try {
      page = page <= 0 ? 1 : page;
      final response = await _getDio().get('$url/$orgId/repositories?orderBy=last_activity_at&perPage=10&sort=desc&page=$page');
      projectList = List<Map<String, dynamic>>.from(
        response.data.map(
          (e) => {
            'id': e['id'],
            'name': e['name'],
            'path': removeFirstSegment(e['pathWithNamespace']).replaceFirst('/${e['name']}', ''),
            'update': formatChatTime(e['lastActivityAt']),
            'desc': e['description'],
          },
        ),
      );
      return projectList;
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
      rethrow;
    } finally {
      loader.hide();
    }
  }

  Future<List<Map<String, dynamic>>> getProjectMrList(BuildContext context, int projectId, String status) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    try {
      final response = await _getDio().get(
        '$url/$orgId/changeRequests?projectIds=$projectId&orderBy=updated_at&state=$status&perPage=10&sort=desc&page=1',
      );
      projectMrList = List<Map<String, dynamic>>.from(
        response.data.map(
          (e) => {
            'id': e['localId'],
            'source': e['sourceBranch'],
            'target': e['targetBranch'],
            'author': e['author']['name'],
            'created': formatChatTime(e['createdAt']),
            'title': e['title'],
            'state': e['state'],
          },
        ),
      );
      return projectMrList;
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
      rethrow;
    } finally {
      loader.hide();
    }
  }

  Future<void> okMr(BuildContext context, int projectId, int localId) async {
    final jsonString = jsonEncode({"mergeMessage": "", "mergeType": "no-fast-forward", "removeSourceBranch": false});
    final loader = context.read<LoadingProvider>();
    loader.show();
    try {
      final response = await _getDio().post(
        '$url/$orgId/repositories/$projectId/changeRequests/$localId/merge',
        data: jsonString,
      );
      if (response.data['status'] == 'MERGED') {
        showSucc('合并成功');
      } else {
        showError('合并失败，请检查状态');
      }
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
      rethrow;
    } finally {
      loader.hide();
    }
  }

  Future<void> closeMr(BuildContext context, int projectId, int localId) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    try {
      final response = await _getDio().post('$url/$orgId/repositories/$projectId/changeRequests/$localId/close');
      if (response.data['result']) {
        showSucc('关闭成功');
      } else {
        showError('关闭失败，请检查状态');
      }
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
      rethrow;
    } finally {
      loader.hide();
    }
  }
}

class CodeUpProvider extends ChangeNotifier {
  List<dynamic> _items = [];

  List<dynamic> get items => _items;

  late ObjectStore<CodeUpModel> _store;

  void save(CodeUpModel item) {
    _setShared();
    _store.save(item.orgId, item);

    list();
  }

  void remove(String id) {
    _setShared();
    _store.remove(id);
    list();
  }

  Future<void> list() async {
    _setShared();
    _items = await _store.list();
    notifyListeners();
  }

  void _setShared() {
    _store = ObjectStore<CodeUpModel>(
      key: 'codeup_map',
      fromJson: (json) => CodeUpModel.fromJson(json),
      toJson: (obj) => obj.toJson(),
    );
  }
}

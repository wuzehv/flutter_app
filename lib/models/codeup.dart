import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/config.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:provider/provider.dart';

import '../common/loading.dart';

const mrStatusOpened = 'opened';
const mrStatusMerged = 'merged';
const mrStatusClosed = 'closed';

class CodeUpModel {
  final String url = Config.CODEUP_URL;
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
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 7)));

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
      final response = await _getDio().get('$url/$orgId/repositories?orderBy=last_activity_at&perPage=15&sort=desc&page=$page');
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
            // 尝试获取 patchSetId，如果接口返回的话
            'sourcePatchSetBizId': e['sourcePatchSetBizId'],
            'targetPatchSetBizId': e['targetPatchSetBizId'],
            'patchSets': e['patchSets'],
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

  Future<Map<String, dynamic>?> okMr(BuildContext context, int projectId, int localId) async {
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
        // 返回合并结果和目标分支
        return {
          'success': true,
          'targetBranch': response.data['targetBranch'],
          'sourceBranch': response.data['sourceBranch'],
        };
      } else {
        showError('合并失败，请检查状态');
        return {'success': false};
      }
    } catch (e) {
      showError('请求失败，请检查网络和配置信息');
      return {'success': false};
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

  /// 获取合并请求详情（用于获取 patchSetId）
  Future<Map<String, dynamic>?> getMrDetail(int projectId, int localId) async {
    try {
      final response = await _getDio().get(
        '$url/$orgId/repositories/$projectId/changeRequests/$localId',
      );
      debugPrint('getMrDetail response: ${response.data}');
      return response.data;
    } catch (e) {
      showError('获取合并请求详情失败: $e');
      return null;
    }
  }

  /// 获取合并请求版本列表（patches）
  /// 返回包含 patchSetBizId 和 relatedMergeItemType 的列表
  /// relatedMergeItemType: MERGE_SOURCE - 源分支, MERGE_TARGET - 目标分支
  Future<List<Map<String, dynamic>>?> getMrPatchSets(int projectId, int localId) async {
    try {
      final response = await _getDio().get(
        '$url/$orgId/repositories/$projectId/changeRequests/$localId/diffs/patches',
      );
      debugPrint('getMrPatchSets response: ${response.data}');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return null;
    } catch (e) {
      showError('获取版本列表失败: $e');
      return null;
    }
  }

  /// 获取合并请求变更文件树
  Future<Map<String, dynamic>?> getMrChangeTree(
    int projectId,
    int localId,
    String fromPatchSetId,
    String toPatchSetId,
  ) async {
    try {
      final response = await _getDio().get(
        '$url/$orgId/repositories/$projectId/changeRequests/$localId/diffs/changeTree?fromPatchSetId=$fromPatchSetId&toPatchSetId=$toPatchSetId',
      );
      return response.data;
    } catch (e) {
      showError('获取变更文件列表失败');
      return null;
    }
  }

  /// 比较两个 commit 获取 diff 内容
  /// [from] 起始版本（commitId/分支名/标签名）- 对应旧版本
  /// [to] 截止版本（commitId/分支名/标签名）- 对应新版本
  Future<Map<String, dynamic>?> compareCommits(
    int projectId,
    String from,
    String to, {
    String? sourceType,
    String? targetType,
  }) async {
    try {
      var queryParams = 'from=$from&to=$to';
      if (sourceType != null) queryParams += '&sourceType=$sourceType';
      if (targetType != null) queryParams += '&targetType=$targetType';
      
      final response = await _getDio().get(
        '$url/$orgId/repositories/$projectId/compares?$queryParams',
      );
      debugPrint('compareCommits response: ${response.data}');
      return response.data;
    } catch (e) {
      showError('获取代码对比失败: $e');
      return null;
    }
  }

  /// 获取项目分支列表（最新修改的前10个）
  /// [projectId] 项目ID
  Future<List<Map<String, dynamic>>> getProjectBranches(int projectId) async {
    try {
      // 使用 API 直接排序：updated_desc 按更新时间降序（最新的在前）
      final response = await _getDio().get(
        '$url/$orgId/repositories/$projectId/branches?perPage=10&sort=updated_desc',
      );
      
      final branches = List<Map<String, dynamic>>.from(
        response.data.map(
          (e) => {
            'name': e['name'],
            'commitId': e['commit']?['id'] ?? '',
            'commitMessage': e['commit']?['message'] ?? e['commit']?['title'] ?? '',
            'committer': e['commit']?['authorName'] ?? e['commit']?['committerName'] ?? '',
            'updatedAt': e['commit']?['committedDate'] ?? e['commit']?['authoredDate'] ?? '',
            'isProtected': e['protected'] ?? false,
          },
        ),
      );
      
      return branches;
    } catch (e) {
      showError('获取分支列表失败，请检查网络和配置信息');
      rethrow;
    }
  }
}

class CodeUpProvider extends ChangeNotifier {
  List<dynamic> _items = [];

  List<dynamic> get items => _items;

  late ObjectStore<CodeUpModel> _store;

  Future<void> save(CodeUpModel item) async {
    _setShared();
    await _store.save(item.orgId, item);
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
    _store = ObjectStore<CodeUpModel>(
      key: 'codeup_map',
      fromJson: (json) => CodeUpModel.fromJson(json),
      toJson: (obj) => obj.toJson(),
    );
  }
}

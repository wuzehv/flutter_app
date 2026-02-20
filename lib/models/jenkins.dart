import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/config.dart';
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
    final response = await _getDio().get('${Config.JENKINS_URL}/open/projects');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<List<Map<String, dynamic>>> getPendingList() async {
    final response = await _getDio().get('${Config.JENKINS_URL}/open/pending?user=$user');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<List<Map<String, dynamic>>> getBuildList(String project) async {
    final response = await _getDio().get('${Config.JENKINS_URL}/open/builds?project=$project');
    return List<Map<String, dynamic>>.from(response.data['data']['data'].map((e) => Map<String, dynamic>.from(e)));
  }

  Future<void> proceedBuild(int id) async {
    try {
      await _getDio().post('${Config.JENKINS_URL}/open/proceed?id=$id');
      showSucc('已通过');
    } catch (e) {
      showError('操作失败，请检查任务');
    }
  }

  Future<void> abortBuild(int id) async {
    try {
      await _getDio().post('${Config.JENKINS_URL}/open/abort?id=$id');
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

  // 获取构建参数的通用方法
  Future<Map<String, dynamic>> getBuildParams(String projectName) async {
    try {
      final response = await _getDio().get('${Config.JENKINS_URL}/open/build_params?project=$projectName');

      if (response.statusCode == 200) {
        // 直接返回需要的数据结构
        final rawData = response.data;
        return rawData['data']?['data'] as Map<String, dynamic>;
      } else {
        throw Exception('API返回状态码: ${response.statusCode}');
      }
    } catch (e) {
      showError('获取构建参数失败: ${e.toString()}');
      rethrow;
    }
  }
  
  /// 通用发布方法
  /// [apiPath] API路径，如 '/wms/publish'
  /// [requestData] 请求数据
  /// [context] BuildContext用于显示提示信息
  Future<bool> publish(String apiPath, Map<String, dynamic> requestData, BuildContext context) async {
    try {
      // 显示加载状态
      showInfo('正在提交发布请求...');

      final response = await _getDio().post('${Config.JENKINS_URL}$apiPath', data: requestData);
      
      // 检查响应数据是否存在
      if (response.data == null) {
        showError('服务器响应数据为空');
        return false;
      }
      
      final responseData = response.data;
      
      // 检查data字段是否存在
      if (responseData['data'] == null) {
        showError('响应数据格式错误：缺少data字段');
        return false;
      }
      
      final data = responseData['data'];
      
      // 根据success字段判断成功失败
      if (data['success'] == true) {
        showSucc('发布请求提交成功');
        return true;
      } else {
        // 失败时处理detail字段
        List<String> detailList = [];
        if (data['detail'] != null) {
          if (data['detail'] is List) {
            detailList = List<String>.from(data['detail']);
          } else if (data['detail'] is String) {
            detailList = [data['detail']];
          }
        }
        
        // 显示失败详情弹窗
        _showFailureDialog(context, detailList);
        return false;
      }
    } catch (e) {
      showError('发布请求提交失败: ${e.toString()}');
      return false;
    }
  }
  
  /// 显示发布失败详情弹窗
  /// [context] BuildContext
  /// [details] 失败详情列表
  void _showFailureDialog(BuildContext context, List<String> details) {
    showDialog(
      context: context,
      barrierDismissible: false, // 不允许点击背景关闭
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[700]),
              SizedBox(width: 8),
              Text('发布失败详情', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共 ${details.length} 个项目发布失败：', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                ),
                SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: details.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  '${index + 1}.', 
                                  style: TextStyle(
                                    color: Colors.red[700], 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  details[index],
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                    height: 1.3
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
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
  bool _isLoading = true; // 初始化时显示加载状态
  
  bool get isLoading => _isLoading;
  
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

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
    
    isLoading = true;
    
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
    } finally {
      isLoading = false;
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

    // 创建待审核列表的副本，避免在遍历时修改原列表
    List<Map<String, dynamic>> itemsToApprove = List.from(pendingList);

    // 遍历所有待审核项，逐一调用单个审核方法
    for (var item in itemsToApprove) {
      try {
        await approveSingleItem(item);
      } catch (e) {
        // 单个审核失败不影响其他项的审核
        print('批量审核中单项失败: ${e.toString()}');
      }
    }
  }

  Future<void> approveSingleItem(Map<String, dynamic> item) async {
    if (_currentJenkins == null) return;

    // 检查必要字段
    final itemId = item['id'];
    if (itemId == null) {
      throw Exception('审核项缺少id字段');
    }

    // 调用您已有的proceedBuild方法
    await _currentJenkins!.proceedBuild(itemId);

    // 从pendingList中移除该项目
    pendingList.removeWhere((element) => element['id'] == itemId);
    pendingApprovalCount = pendingList.length;
    notifyListeners();
  }

  Future<void> rejectSingleItem(Map<String, dynamic> item) async {
    if (_currentJenkins == null) return;

    // 检查必要字段
    final itemId = item['id'];
    if (itemId == null) {
      throw Exception('审核项缺少id字段');
    }

    // 调用您已有的abortBuild方法
    await _currentJenkins!.abortBuild(itemId);

    // 从pendingList中移除该项目
    pendingList.removeWhere((element) => element['id'] == itemId);
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

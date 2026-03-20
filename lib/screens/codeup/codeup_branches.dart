import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

import '../../common/loading.dart';

class CodeUpBranches extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpBranches({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpBranchesState();
}

class _CodeUpBranchesState extends State<CodeUpBranches> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 安全格式化时间
  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '未知时间';
    try {
      return formatChatTime(timeStr);
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final branches = await widget.codeup.getProjectBranches(widget.codeup.curProjectId);

      setState(() {
        _branches = branches;
      });
    } catch (e) {
      print('加载分支列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示发布选择弹窗
  void _showPublishDialog(String branchName) {
    // 获取可用的 Jenkins 配置
    final jenkinsProvider = context.read<JenkinsProvider>();
    final jenkinsList = jenkinsProvider.items;

    if (jenkinsList.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('提示'),
          content: Text('未配置 Jenkins，无法跳转发布页面'),
          actions: [
            TextButton(onPressed: () => context.pop(), child: Text('确定')),
          ],
        ),
      );
      return;
    }

    // 显示发布类型选择
    _showPublishTypeSelector(jenkinsList, branchName);
  }

  /// 显示发布类型选择弹窗
  void _showPublishTypeSelector(List<dynamic> jenkinsList, String branchName) async {
    // 提前加载所有 Jenkins 的项目列表，避免弹窗内使用 FutureBuilder 导致闪屏
    final Map<JenkinsModel, List<Map<String, dynamic>>> jenkinsProjectsMap = {};
    for (var jenkins in jenkinsList) {
      try {
        final projects = await jenkins.getJobList();
        jenkinsProjectsMap[jenkins] = projects;
      } catch (e) {
        jenkinsProjectsMap[jenkins] = [];
      }
    }

    if (!context.mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PublishConfigDialog(
          jenkinsList: jenkinsList,
          jenkinsProjectsMap: jenkinsProjectsMap,
        );
      },
    );

    // 只有点击确定并返回有效数据时才跳转
    if (result != null && context.mounted) {
      _navigateToPublishPage(
        result['jenkins'] as JenkinsModel,
        result['projectName'] as String,
        result['publishType'] as String,
        branchName,
      );
    }
  }

  /// 跳转到发布页面
  void _navigateToPublishPage(
    JenkinsModel jenkins,
    String projectName,
    String publishType,
    String branchName,
  ) {
    final path = publishType == 'wms' ? '/job/build_wms' : '/job/build_shipla';
    context.push(
      path,
      extra: {
        'obj': jenkins,
        'name': projectName,
        'targetBranch': branchName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.codeup.curProjectName} - 分支'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(),
        child: _isLoading && _branches.isEmpty
            ? Center(child: CircularProgressIndicator())
            : _branches.isEmpty
                ? Center(child: Text('暂无分支'))
                : ListView.separated(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                  final isProtected = branch['isProtected'] ?? false;

                  return ListTile(
                    leading: Icon(
                      Icons.call_split,
                      color: isProtected ? Colors.orange : Colors.blue,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isProtected ? Colors.orange : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isProtected)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '保护',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${branch['committer']} · 更新于 ${_formatTime(branch['updatedAt'])}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'publish') {
                          _showPublishDialog(branch['name']);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(Icons.rocket_launch, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('发布'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // 显示分支详情或操作
                      _showBranchDetail(branch);
                    },
                  );
                },
                separatorBuilder: (context, index) => Divider(height: 0.5),
              ),
      ),
    );
  }

  /// 显示分支详情弹窗
  void _showBranchDetail(Map<String, dynamic> branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(branch['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('提交ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(branch['commitId'] ?? '', style: TextStyle(fontSize: 12)),
            SizedBox(height: 12),
            Text('提交信息:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(branch['commitMessage'] ?? '无'),
            SizedBox(height: 12),
            Text('提交人:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(branch['committer'] ?? '未知'),
            SizedBox(height: 12),
            Text('更新时间:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatTime(branch['updatedAt'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.pop();
              _showPublishDialog(branch['name']);
            },
            icon: Icon(Icons.rocket_launch, size: 18),
            label: Text('发布'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// 发布配置选择弹窗
class _PublishConfigDialog extends StatefulWidget {
  final List<dynamic> jenkinsList;
  final Map<JenkinsModel, List<Map<String, dynamic>>> jenkinsProjectsMap;

  const _PublishConfigDialog({
    required this.jenkinsList,
    required this.jenkinsProjectsMap,
  });

  @override
  State<_PublishConfigDialog> createState() => _PublishConfigDialogState();
}

class _PublishConfigDialogState extends State<_PublishConfigDialog> {
  JenkinsModel? selectedJenkins;
  String? selectedProjectName;
  String? selectedPublishType;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('选择发布配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发布类型选择
            Text('发布类型:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: Text('WMS'),
                  selected: selectedPublishType == 'wms',
                  onSelected: (selected) {
                    setState(() {
                      selectedPublishType = selected ? 'wms' : null;
                    });
                  },
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Shipla'),
                  selected: selectedPublishType == 'shipla',
                  onSelected: (selected) {
                    setState(() {
                      selectedPublishType = selected ? 'shipla' : null;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Jenkins 配置选择
            Text('Jenkins 配置:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...widget.jenkinsList.map((jenkins) {
              return RadioListTile<JenkinsModel>(
                title: Text(jenkins.remark),
                value: jenkins,
                groupValue: selectedJenkins,
                onChanged: (value) {
                  setState(() {
                    selectedJenkins = value;
                    selectedProjectName = null;
                  });
                },
              );
            }).toList(),
            // 项目选择（选择 Jenkins 后显示）
            if (selectedJenkins != null) ...[
              SizedBox(height: 16),
              Text('项目名称:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Builder(builder: (context) {
                final projects = widget.jenkinsProjectsMap[selectedJenkins] ?? [];
                if (projects.isEmpty) {
                  return Text('该项目没有可用发布');
                }
                return Column(
                  children: projects.map((project) {
                    return RadioListTile<String>(
                      title: Text(project['name']),
                      value: project['name'],
                      groupValue: selectedProjectName,
                      onChanged: (value) {
                        setState(() {
                          selectedProjectName = value;
                        });
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (selectedPublishType == null) {
              showError('请选择发布类型');
              return;
            }
            if (selectedJenkins == null) {
              showError('请选择 Jenkins 配置');
              return;
            }
            if (selectedProjectName == null) {
              showError('请选择项目');
              return;
            }
            Navigator.of(context).pop({
              'jenkins': selectedJenkins,
              'projectName': selectedProjectName,
              'publishType': selectedPublishType,
            });
          },
          child: Text('确定', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

import '../../common/util.dart';

class CodeUpMr extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpMr({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpMrState();
}

class _CodeUpMrState extends State<CodeUpMr> with SingleTickerProviderStateMixin {
  final Map<String, List<Map<String, dynamic>>> _itemsMap = {};

  late TabController _tabController;
  final List<String> _statuses = [mrStatusOpened, mrStatusMerged, mrStatusClosed, 'null'];
  final List<String> _tabTitles = ['已开启', '已合并', '已关闭', '全部'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);

    // 监听 tab 切换
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // 避免快速切换时重复触发
      final status = _statuses[_tabController.index];
      _loadData(status);
    });

    // 首次加载，直接调用_loadData会导致build之前调用了setState，包一下
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(_statuses[0]);
    });
  }

  Future<void> _loadData(String status) async {
    final pageItems = await widget.codeup.getProjectMrList(context, widget.codeup.curProjectId, status);
    setState(() {
      _itemsMap[status] = pageItems;
    });
  }

  /// 显示发布确认弹窗
  void _showPublishConfirmDialog(String? targetBranch) async {
    // 获取可用的 Jenkins 配置
    final jenkinsProvider = context.read<JenkinsProvider>();
    final jenkinsList = jenkinsProvider.items;

    if (jenkinsList.isEmpty) {
      // 没有配置 Jenkins，提示用户
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

    // 显示二次确认弹窗
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('合并成功'),
        content: Text('是否跳转到发布页面？'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('确认', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (shouldPublish == true && context.mounted) {
      // 选择发布类型和 Jenkins 配置
      _showPublishTypeSelector(jenkinsList, targetBranch);
    }
  }

  /// 显示发布类型选择弹窗
  void _showPublishTypeSelector(List<dynamic> jenkinsList, String? targetBranch) async {
    // 默认选择第一个 Jenkins 配置
    JenkinsModel? selectedJenkins;
    String? selectedProjectName;
    String? selectedPublishType; // 'wms' 或 'shipla'

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('选择发布配置'),
              content: Column(
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
                          setDialogState(() {
                            selectedPublishType = selected ? 'wms' : null;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Shipla'),
                        selected: selectedPublishType == 'shipla',
                        onSelected: (selected) {
                          setDialogState(() {
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
                  ...jenkinsList.map((jenkins) {
                    return RadioListTile<JenkinsModel>(
                      title: Text(jenkins.remark),
                      value: jenkins,
                      groupValue: selectedJenkins,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedJenkins = value;
                          selectedProjectName = null; // 重置项目选择
                        });
                      },
                    );
                  }).toList(),
                  // 项目选择（选择 Jenkins 后显示）
                  if (selectedJenkins != null) ...[
                    SizedBox(height: 16),
                    Text('项目名称:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    FutureBuilder(
                      future: selectedJenkins!.getJobList(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('加载失败: ${snapshot.error}', style: TextStyle(color: Colors.red));
                        }
                        final projects = snapshot.data ?? [];
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
                                setDialogState(() {
                                  selectedProjectName = value;
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
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
                    context.pop();
                  },
                  child: Text('确定', style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );

    // 跳转到发布页面
    if (selectedJenkins != null && selectedProjectName != null && selectedPublishType != null && context.mounted) {
      _navigateToPublishPage(selectedJenkins!, selectedProjectName!, selectedPublishType!, targetBranch);
    }
  }

  /// 跳转到发布页面
  void _navigateToPublishPage(
    JenkinsModel jenkins,
    String projectName,
    String publishType,
    String? targetBranch,
  ) {
    final path = publishType == 'wms' ? '/job/build_wms' : '/job/build_shipla';
    context.push(
      path,
      extra: {
        'obj': jenkins,
        'name': projectName,
        'targetBranch': targetBranch, // 传入目标分支
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.codeup.curProjectName),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          final items = _itemsMap[status] ?? [];
          return RefreshIndicator(
            onRefresh: () async => _loadData(status),
            child: items.isNotEmpty
                ? ListView.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          Icons.mediation_rounded,
                          color: items[index]['state'] == 'CLOSED'
                              ? Colors.red
                              : items[index]['state'] == 'MERGED'
                              ? Colors.grey
                              : Colors.green,
                        ),
                        title: Text(items[index]['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${items[index]['source']} -> ${items[index]['target']}'),
                            Text('${items[index]['author']} 创建于 ${items[index]['created']}'),
                            if (!['CLOSED', 'MERGED', 'TO_BE_MERGED'].contains(items[index]['state']))
                              Text(
                                items[index]['state'],
                                style: TextStyle(backgroundColor: Colors.red, color: Colors.white),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                // Diff 按钮
                                _buildActionButton(
                                  icon: Icons.compare_arrows,
                                  label: 'Diff',
                                  color: Colors.blue,
                                  onPressed: () {
                                    final sourcePatchSetId = items[index]['sourcePatchSetBizId']?.toString();
                                    final targetPatchSetId = items[index]['targetPatchSetBizId']?.toString();
                                    context.push(
                                      '/codeup/project/mr_diff',
                                      extra: {
                                        'codeup': widget.codeup,
                                        'projectId': widget.codeup.curProjectId,
                                        'mrId': items[index]['id'],
                                        'mrTitle': items[index]['title'],
                                        'sourcePatchSetBizId': sourcePatchSetId,
                                        'targetPatchSetBizId': targetPatchSetId,
                                      },
                                    );
                                  },
                                ),
                                // 关闭按钮
                                if (!['CLOSED', 'MERGED'].contains(items[index]['state']))
                                  _buildActionButton(
                                    icon: Icons.close,
                                    label: '关闭',
                                    color: Colors.red,
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (content) {
                                          return AlertDialog(
                                            content: Text("确认关闭合并请求吗?"),
                                            actions: <Widget>[
                                              TextButton(child: Text("取消"), onPressed: () => context.pop()),
                                              TextButton(
                                                child: Text("确认"),
                                                onPressed: () {
                                                  widget.codeup.closeMr(context, widget.codeup.curProjectId, items[index]['id']);
                                                  context.pop();
                                                  _loadData(status);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                // 合并按钮
                                if (items[index]['state'] == 'TO_BE_MERGED')
                                  _buildActionButton(
                                    icon: Icons.check,
                                    label: '合并',
                                    color: Colors.green,
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (content) {
                                          return AlertDialog(
                                            content: Text("确认完成合并请求吗?"),
                                            actions: <Widget>[
                                              TextButton(child: Text("取消"), onPressed: () => context.pop()),
                                              TextButton(
                                                child: Text("确认"),
                                                onPressed: () async {
                                                  final result = await widget.codeup.okMr(context, widget.codeup.curProjectId, items[index]['id']);
                                                  context.pop();
                                                  if (result != null && result['success'] == true) {
                                                    final targetBranch = result['targetBranch'] as String?;
                                                    _showPublishConfirmDialog(targetBranch);
                                                  }
                                                  _loadData(status);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(height: .0),
                  )
                : ListView(
                    children: [SizedBox(height: 300, child: Center(child: Text('暂无数据')))],
                  ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withAlpha((0.1 * 255).toInt()),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

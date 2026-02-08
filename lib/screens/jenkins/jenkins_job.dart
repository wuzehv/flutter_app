import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';
import 'pending_approval_item.dart';

class JenkinsJob extends StatefulWidget {
  final String name;

  const JenkinsJob({super.key, required this.name});

  @override
  State<StatefulWidget> createState() => _JenkinsJobState();
}

class _JenkinsJobState extends State<JenkinsJob> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化时获取待审核数据
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<JenkinsJobProvider>().fetchPendingApproval();
      } catch (e) {
        // 错误处理
      }
    });
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
        title: Text(widget.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: '项目列表',
              icon: Icon(Icons.list_alt),
            ),
            Consumer<JenkinsJobProvider>(
              builder: (context, provider, child) {
                return Tab(
                  text: provider.pendingApprovalCount > 0 
                    ? '待你审核 (${provider.pendingApprovalCount}) '
                    : '待你审核',
                  icon: Icon(
                    provider.pendingApprovalCount > 0 
                      ? Icons.notifications 
                      : Icons.notifications_none,
                    color: provider.pendingApprovalCount > 0 
                      ? Colors.red 
                      : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 项目列表 Tab
          Consumer<JenkinsJobProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                itemCount: provider.jobs.length,
                itemBuilder: (context, index) {
                  final job = provider.jobs[index];

                  return Selector<JenkinsJobProvider, bool>(
                    selector: (_, provider) => provider.isExpanded(job.name),
                    builder: (context, expanded, child) {
                      final jobProvider = context.read<JenkinsJobProvider>();

                      return ExpansionTile(
                        title: Text(job.name),
                        initiallyExpanded: expanded,
                        onExpansionChanged: (_) => jobProvider.toggleExpanded(job.name),
                        children: [
                          ListTile(
                            title: Text('开始发布', style: TextStyle(color: Colors.green)),
                            leading: Icon(Icons.play_arrow, color: Colors.green),
                            onTap: () async {
                              // 根据项目名称判断跳转到不同的发布页面
                              String routePath;
                              if (job.name.toLowerCase().contains('shipla')) {
                                routePath = '/job/build_shipla';
                              } else {
                                routePath = '/job/build_wms';
                              }
                              
                              context.push(routePath, extra: {
                                'obj': provider.currentJenkins,
                                'name': job.name,
                              });
                            },
                          ),
                          ListTile(
                            title: Text('发布历史', style: TextStyle(color: Colors.orange)),
                            leading: Icon(Icons.history, color: Colors.orange),
                            onTap: () {
                              // 跳转到 jenkins_log 页面，并传递当前 job 的名称
                              context.push('/job/log', extra: {
                                'obj': provider.currentJenkins,
                                'name': job.name,
                                'jobs': List<String>.from(provider.projectList[index]['jobs'])
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          // 待你审核 Tab
          Consumer<JenkinsJobProvider>(
            builder: (context, provider, child) {
              if (provider.pendingApprovalCount == 0) {
                return RefreshIndicator(
                  onRefresh: () async {
                    try {
                      await context.read<JenkinsJobProvider>().fetchPendingApproval();
                    } catch (e) {
                      // 错误处理
                    }
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无待审核内容',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  try {
                    await context.read<JenkinsJobProvider>().fetchPendingApproval();
                  } catch (e) {
                    // 错误处理
                  }
                },
                child: Column(
                  children: [
                    // 一键审核按钮
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await context.read<JenkinsJobProvider>().approveAllPending();
                                  showSucc('批量审核完成');
                                } catch (e) {
                                  showError('批量审核失败，请重试');
                                }
                              },
                              icon: Icon(Icons.done_all, color: Colors.white),
                              label: Text('一键审核全部', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,  // 改为绿色，与单个审核通过按钮一致
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 待审核列表
                    Flexible(
                      child: ListView.builder(
                        itemCount: provider.getPendingList.length,
                        itemBuilder: (context, index) {
                          final item = provider.getPendingList[index];
                          return PendingApprovalItem(
                            item: item,
                            currentUser: provider.currentJenkins?.user ?? '',
                            onReject: () {
                              // 调用审核拒绝接口
                              try {
                                context.read<JenkinsJobProvider>().rejectSingleItem(item);
                                showInfo('已拒绝');
                              } catch (e) {
                                showError('拒绝失败');
                              }
                            },
                            onApprove: () {
                              // 调用审核通过接口
                              try {
                                context.read<JenkinsJobProvider>().approveSingleItem(item);
                                showInfo('已通过');
                              } catch (e) {
                                showError('通过失败');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
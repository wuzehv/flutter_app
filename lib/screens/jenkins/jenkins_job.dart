import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

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
                    ? '待你审核 (${provider.pendingApprovalCount})' 
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
                              try {
                                await context
                                    .read<JenkinsProjectProvider>()
                                    .setJenkins(provider.currentJenkins!)
                                    .fetchProjects(job.name);
                                context.push('/job/project', extra: job.name);
                              } catch (e) {
                                showError('请求失败，请检查网络和配置信息');
                              }
                            },
                          ),
                          ListTile(
                            title: Text('发布历史', style: TextStyle(color: Colors.orange)),
                            leading: Icon(Icons.history, color: Colors.orange),
                            onTap: () {
                              // TODO: 实现发布历史功能
                              showInfo('发布历史功能待实现');
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
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Text('【${item['country'] ?? ''}】 '),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (item['branch'] ?? '').toString().length > 25 
                                          ? (item['branch'] ?? '').toString().substring(0, 25) + '...'
                                          : item['branch'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '${item['show_time'] ?? ''}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                subtitle: Text('${item['real_project'] ?? '未知项目'} by ${item['creator'] ?? '未知提交者'}'),
                                leading: Icon(Icons.pending_actions, color: Colors.orange),
                                childrenPadding: EdgeInsets.all(0),
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('构建参数:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: (item['build_params'] as List<dynamic>?)?.map((param) {
                                            final p = param as Map<String, dynamic>;
                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                                              child: Wrap(
                                                alignment: WrapAlignment.start,
                                                crossAxisAlignment: WrapCrossAlignment.start,
                                                spacing: 8,
                                                children: [
                                                  Text('${p['name']}:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(p['value']?.toString() ?? '', softWrap: true,),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList() ?? [],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // 调用审核拒绝接口
                                                  try {
                                                    context.read<JenkinsJobProvider>().rejectSingleItem(item);
                                                    showInfo('已拒绝');
                                                  } catch (e) {
                                                    showError('拒绝失败');
                                                  }
                                                },
                                                icon: Icon(Icons.close, color: Colors.white),
                                                label: Text('拒绝', style: TextStyle(color: Colors.white)),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // 调用审核通过接口
                                                  try {
                                                    context.read<JenkinsJobProvider>().approveSingleItem(item);
                                                    showInfo('已通过');
                                                  } catch (e) {
                                                    showError('通过失败');
                                                  }
                                                },
                                                icon: Icon(Icons.check, color: Colors.white),
                                                label: Text('通过', style: TextStyle(color: Colors.white)),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
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

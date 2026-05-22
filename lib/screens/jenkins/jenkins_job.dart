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

class _JenkinsJobState extends State<JenkinsJob>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<JenkinsJobProvider>().fetchPendingApproval();
      } catch (e) {
        // 静默处理
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      Future.microtask(() async {
        try {
          await context.read<JenkinsJobProvider>().fetchPendingApproval();
        } catch (e) {
          // 静默处理
        }
      });
    }
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
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            const Tab(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 18),
                  SizedBox(width: 6),
                  Text('项目列表'),
                ],
              ),
            ),
            Consumer<JenkinsJobProvider>(
              builder: (context, provider, child) {
                return Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: provider.pendingApprovalCount > 0,
                        smallSize: 8,
                        child: const Icon(Icons.notifications_none, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.pendingApprovalCount > 0
                            ? '待审核 (${provider.pendingApprovalCount})'
                            : '待审核',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _JobListTab(),
          _PendingApprovalTab(),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// 项目列表 Tab
// ───────────────────────────────────────────────
class _JobListTab extends StatelessWidget {
  const _JobListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<JenkinsJobProvider>(
      builder: (context, provider, child) {
        if (provider.jobs.isEmpty) {
          return _EmptyState(
            icon: Icons.folder_open_outlined,
            title: '暂无项目',
            subtitle: '该 Jenkins 配置下没有找到项目',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.jobs.length,
          itemBuilder: (context, index) {
            final job = provider.jobs[index];
            return _JobCard(
              job: job,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final JenkinsJobModel job;
  final int index;

  const _JobCard({required this.job, required this.index});

  @override
  Widget build(BuildContext context) {
    return Selector<JenkinsJobProvider, bool>(
      selector: (_, p) => p.isExpanded(job.name),
      builder: (context, expanded, child) {
        final provider = context.read<JenkinsJobProvider>();

        return Card(
          elevation: 2,
          shadowColor: Colors.black.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    _IconContainer(
                      icon: Icons.settings,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '点击展开操作',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: expanded,
                onExpansionChanged: (_) => provider.toggleExpanded(job.name),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.play_arrow_rounded,
                            label: '开始发布',
                            color: Colors.green,
                            onTap: () {
                              context.push('/job/build_${job.name}', extra: {
                                'obj': provider.currentJenkins,
                                'name': job.name,
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.history_rounded,
                            label: '发布历史',
                            color: Colors.orange,
                            onTap: () {
                              context.push('/job/log', extra: {
                                'obj': provider.currentJenkins,
                                'name': job.name,
                                'jobs': List<String>.from(
                                  provider.projectList[index]['jobs'],
                                ),
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────
// 待审核 Tab
// ───────────────────────────────────────────────
class _PendingApprovalTab extends StatelessWidget {
  const _PendingApprovalTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<JenkinsJobProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const _LoadingState();
        }

        if (provider.pendingApprovalCount == 0) {
          return RefreshIndicator(
            onRefresh: () async {
              try {
                await context.read<JenkinsJobProvider>().fetchPendingApproval();
              } catch (e) {
                // 静默处理
              }
            },
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _EmptyState(
                    icon: Icons.check_circle_outline,
                    title: '暂无待审核',
                    subtitle: '当前没有需要您审核的任务',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            try {
              await context.read<JenkinsJobProvider>().fetchPendingApproval();
            } catch (e) {
              // 静默处理
            }
          },
          child: Column(
            children: [
              // 一键审核
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          try {
                            await context
                                .read<JenkinsJobProvider>()
                                .approveAllPending();
                            showSucc('批量审核完成');
                          } catch (e) {
                            showError('批量审核失败，请重试');
                          }
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text(
                          '一键审核全部',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 列表
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: provider.getPendingList.length,
                  itemBuilder: (context, index) {
                    final item = provider.getPendingList[index];
                    return PendingApprovalItem(
                      item: item,
                      currentUser: provider.currentJenkins?.user ?? '',
                      onReject: () {
                        context
                            .read<JenkinsJobProvider>()
                            .rejectSingleItem(item);
                      },
                      onApprove: () {
                        context
                            .read<JenkinsJobProvider>()
                            .approveSingleItem(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────
// 通用组件
// ───────────────────────────────────────────────

/// 图标容器（与 Dashboard 风格一致）
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconContainer({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// 操作小卡片
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态（与 Dashboard 风格一致）
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载状态
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

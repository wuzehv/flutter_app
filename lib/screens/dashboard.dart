import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'package:flutter_app_update/result_model.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/config.dart';

import 'package:jenkins_app/common/loading.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/left_drawer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// 新首页 - 统一仪表板设计
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late String _upgrade;
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    _upgrade = Config.UPGRADE_URL;
    _loadData();
    // web 编译注释掉 Android 更新相关代码
    // if (Platform.isAndroid) {
    //   _initUpdateListener();
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _checkVersion();
    //   });
    // }
  }

  Future<void> _loadData() async {
    await context.read<JenkinsProvider>().list();
    await context.read<CodeUpProvider>().list();
  }

  void _initUpdateListener() {
    AzhonAppUpdate.listener((ResultModel result) {
      switch (result.type) {
        case ResultType.start:
          setState(() => _progressNotifier.value = 0);
          _showProgressDialog();
          break;
        case ResultType.downloading:
          setState(() => _progressNotifier.value = result.progress! / result.max!);
          break;
        case ResultType.done:
          setState(() => _progressNotifier.value = 1.0);
          context.pop();
          break;
        case ResultType.error:
          setState(() => _progressNotifier.value = 0);
          context.pop();
          showError('下载失败，请重试');
          break;
        default:
          break;
      }
    });
  }

  Future<void> _checkVersion() async {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));
    dio.options.headers['Content-Type'] = 'application/json';
    try {
      final response = await dio.get('$_upgrade/version.json');
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (compareVersions(response.data['version'].toString(), packageInfo.version) == 1) {
        final result = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("发现新版本"),
            content: Text(response.data['message']),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  context.pop('confirm');
                  final model = UpdateModel(
                    '$_upgrade/app-release.apk',
                    'jenkinsApp.apk',
                    'ic_launcher',
                    '',
                    showNotification: true,
                  );
                  AzhonAppUpdate.update(model);
                },
                child: const Text("下载更新"),
              ),
            ],
          ),
        );
        // web 编译注释掉 exit
        // if (result == null) {
        //   exit(0);
        // }
      }
    } catch (e) {
      showInfo('检查升级失败，请检查网络');
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("正在下载更新"),
        content: ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              const SizedBox(height: 20),
              Text("${(value * 100).toStringAsFixed(0)}%"),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("DevOps 控制台"),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.blue),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: const LeftDrawer(),

        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jenkins 区域
                _buildSectionHeader(
                  icon: Icons.build_circle,
                  iconColor: Colors.blue,
                  title: 'Jenkins 发布',
                  onAdd: () => context.push('/jenkins_config'),
                ),
                const SizedBox(height: 12),
                Consumer<JenkinsProvider>(
                  builder: (context, provider, child) {
                    if (provider.items.isEmpty) {
                      return _buildEmptyCard('添加 Jenkins 配置', () => context.push('/jenkins_config'));
                    }
                    return _buildCardGrid(
                      items: provider.items,
                      itemBuilder: (jenkins) => _JenkinsCard(
                        jenkins: jenkins,
                        onTap: () async {
                          await context.read<JenkinsJobProvider>().setJenkins(jenkins).fetchJobs();
                          if (context.mounted) {
                            context.push('/job', extra: jenkins.remark);
                          }
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // CodeUp 区域
                _buildSectionHeader(
                  icon: Icons.code,
                  iconColor: Colors.green,
                  title: 'CodeUp 代码管理',
                  onAdd: () => context.push('/codeup_config'),
                ),
                const SizedBox(height: 12),
                Consumer<CodeUpProvider>(
                  builder: (context, provider, child) {
                    if (provider.items.isEmpty) {
                      return _buildEmptyCard('添加 CodeUp 配置', () => context.push('/codeup_config'));
                    }
                    return _buildCardGrid(
                      items: provider.items,
                      itemBuilder: (codeup) => _CodeUpCard(
                        codeup: codeup,
                        onTap: () async {
                          final loader = context.read<LoadingProvider>();
                          loader.show();
                          try {
                            await codeup.getProjectList(context, 1);
                            if (context.mounted) {
                              context.push('/codeup/project', extra: codeup);
                            }
                          } catch (e) {
                            // 错误已在 model 中处理
                          } finally {
                            loader.hide();
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: iconColor.withAlpha((0.1 * 255).toInt()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.blue.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.blue, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空状态卡片
  Widget _buildEmptyCard(String text, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 28, color: Colors.blue[400]),
              ),
              const SizedBox(height: 12),
              Text(
                text, 
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击添加', 
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建卡片网格
  Widget _buildCardGrid<T>({
    required List<T> items,
    required Widget Function(T) itemBuilder,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AzhonAppUpdate.dispose();
    super.dispose();
  }
}

/// Jenkins 卡片
class _JenkinsCard extends StatelessWidget {
  final JenkinsModel jenkins;
  final VoidCallback onTap;

  const _JenkinsCard({required this.jenkins, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.build, color: Colors.blue, size: 20),
                  ),
                  const Spacer(),
                  // 弹出菜单按钮
                  PopupMenuButton<String>(
                    offset: const Offset(0, 30),
                    icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push('/jenkins_config', extra: jenkins);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除 "${jenkins.remark}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => context.pop(true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<JenkinsProvider>().remove(jenkins.id!);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('修改'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                jenkins.remark,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // 显示用户名
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      jenkins.user,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CodeUp 卡片
class _CodeUpCard extends StatelessWidget {
  final CodeUpModel codeup;
  final VoidCallback onTap;

  const _CodeUpCard({required this.codeup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.code, color: Colors.green, size: 20),
                  ),
                  const Spacer(),
                  // 弹出菜单按钮
                  PopupMenuButton<String>(
                    offset: const Offset(0, 30),
                    icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push('/codeup_config', extra: codeup);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除 "${codeup.remark}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => context.pop(true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<CodeUpProvider>().remove(codeup.orgId);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('修改'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                codeup.remark,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // 显示组织ID
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '组织: ${codeup.orgId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'package:flutter_app_update/result_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/home_bottom.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/common/config.dart';
// import 'package:jenkins_app/common/biometric_provider.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_item.dart';
import 'package:jenkins_app/screens/left_drawer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late String _upgrade;

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _upgrade = Config.UPGRADE_URL;
    _loadList();
    // web 编译注释掉 Android 更新相关代码
    // if (Platform.isAndroid) {
    //   _initUpdateListener();
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _checkVersion();
    //   });
    // }
  }

  Future<void> _loadList() async {
    await context.read<JenkinsProvider>().list();
  }

  void _initUpdateListener() {
    AzhonAppUpdate.listener((ResultModel result) {
      switch (result.type) {
        case ResultType.start:
          setState(() {
            _progressNotifier.value = 0;
          });
          _showProgressDialog();
          break;
        case ResultType.downloading:
          setState(() {
            _progressNotifier.value = result.progress! / result.max!;
          });
          break;
        case ResultType.done:
          setState(() {
            _progressNotifier.value = 1.0;
          });
          context.pop();
          break;
        case ResultType.error:
          setState(() {
            _progressNotifier.value = 0;
          });
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
      return;
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("正在下载更新"),
          content: ValueListenableBuilder<double>(
            valueListenable: _progressNotifier,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 20),
                  Text("${(value * 100).toStringAsFixed(0)}%"),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 PopScope 处理返回手势，将应用移到后台
    return PopScope(
      canPop: false, // 禁止默认返回行为
      onPopInvoked: (didPop) {
        if (didPop) return;
        // 返回手势时，将应用移到后台（类似 Home 键）
        print('🏠 返回手势被拦截，将应用移到后台');
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Jenkins列表"),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.dashboard, color: Colors.blue),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: LeftDrawer(),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add',
          onPressed: () => context.push('/jenkins_config'),
          tooltip: '添加配置',
          shape: CircleBorder(),
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: HomeBottom(pageIdx: 0),
        body: Consumer<JenkinsProvider>(
          builder: (context, provider, child) {
            return provider.items.isEmpty
                ? Center(child: Text('请添加配置'))
                : SafeArea(
                    child: SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        itemCount: provider.items.length,
                        itemBuilder: (context, index) => JenkinsItem(jenkins: provider.items[index]),
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AzhonAppUpdate.dispose();
    super.dispose();
  }

  /// 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🏠 Home 生命周期状态: $state');
    
    /* final biometricProvider = context.read<BiometricProvider>();
    
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台（按 Home 键），不设置验证
        print('🏠 应用进入后台，保持验证状态: isAuthenticated=${biometricProvider.isAuthenticated}');
        break;
      case AppLifecycleState.resumed:
        // 应用从后台恢复到前台，不需要验证
        print('🏠 应用从后台恢复，当前验证状态: isAuthenticated=${biometricProvider.isAuthenticated}');
        break;
      case AppLifecycleState.inactive:
        // 应用处于中间状态（通常发生在 iOS 来电或用户通知时）
        break;
      case AppLifecycleState.detached:
        // 注意：返回手势也可能触发 detached，所以不在这里重置
        // 只在点击"退出应用"按钮时主动调用 reset()
        print('🏠 应用 detached，不自动重置验证状态');
        break;
      case AppLifecycleState.hidden:
        // 应用不可见（通常是 Android 的画中画模式等）
        break;
    } */
  }

  /// 退出应用时设置需要验证
  Future<void> _exitApp() async {
    // final biometricProvider = context.read<BiometricProvider>();
    // 重置认证状态，下次启动时需要验证
    // biometricProvider.reset();
    
    // 延迟一小段时间确保状态保存
    await Future.delayed(Duration(milliseconds: 100));
    
    // 退出应用（web 编译注释掉 Platform 相关代码）
    // if (Platform.isAndroid) {
    //   SystemNavigator.pop();
    // } else if (Platform.isIOS) {
    //   exit(0);
    // }
  }
}

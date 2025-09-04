import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'package:flutter_app_update/result_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/home_bottom.dart';
import 'package:jenkins_app/common/util.dart';
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

class _HomeState extends State<Home> {
  final String _upgrade = 'http://192.168.5.60:10000';

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _loadList();
    if (Platform.isAndroid) {
      _initUpdateListener();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVersion();
      });
    }
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

        if (result == null) {
          exit(0);
        }
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
    return Scaffold(
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
    );
  }

  @override
  void dispose() {
    AzhonAppUpdate.dispose();
    super.dispose();
  }
}

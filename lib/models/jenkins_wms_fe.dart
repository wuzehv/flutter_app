import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/global.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/models/loading.dart';
import 'package:provider/provider.dart';

class JenkinsWmsFe extends JenkinsProjectModel {
  final BuildContext context;
  final JenkinsModel jenkins;

  JenkinsWmsFe(this.context, this.jenkins, {required super.name});

  @override
  List<Widget> getOperation() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            children: [
              Row(
                children: [
                  ElevatedButton(onPressed: () => _toBuildPage('tra'), child: Text("tra")),
                  SizedBox(width: 7),
                  ElevatedButton(onPressed: () => _toBuildPage('pro'), child: Text("pro")),
                  SizedBox(width: 7),
                  ElevatedButton(onPressed: () => _toBuildPage('customize'), child: Text("自定义")),
                  SizedBox(width: 7),
                  ElevatedButton.icon(
                    onPressed: () => _toLogPage(),
                    icon: Icon(Icons.playlist_add_check_outlined),
                    label: Text("审核"),
                  ),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 3.0)),
            ],
          ),
        ],
      ),
    ];
  }

  Future<void> _toBuildPage(String env) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    var envParams = env.toLowerCase();
    var idx = name != wmsUi ? 2 : 4;
    try {
      final response = await jenkins.dio.post(
        '${jenkins.url}/job/$name/api/json?tree=property[parameterDefinitions[name,choices]]',
      );
      // env
      Map<String, bool> e = {};
      for (var i in response.data['property'][idx]['parameterDefinitions'][2]['choices']) {
        if (['tra', 'pro'].contains(envParams)) {
          if (i.toString().toLowerCase().contains(envParams)) {
            e[i] = true;
          }
        } else {
          e[i] = false;
        }
      }
      // 审核人
      List<String> a = [];
      for (var i in response.data['property'][idx]['parameterDefinitions'][3]['choices']) {
        a.add(i);
      }

      context.push('/job/project/wms_fe_build', extra: {'obj': this, 'env': envParams, 'env_list': e, 'approver': a});
    } catch (e) {
      showError('读取配置失败，请检查');
    } finally {
      loader.hide();
    }
  }

  Stream<(String, bool)> doBuild(
    BuildContext context,
    List<String> inputEnv,
    String approver,
    String branch,
  ) {
    final controller = StreamController<(String, bool)>();
    int remaining = inputEnv.length;

    for (var e in inputEnv) {
      jenkins.dio
          .post(
            '${jenkins.url}/job/$name/buildWithParameters',
            data: FormData.fromMap({
              "deploy_branch": branch,
              "deploy_environment": e,
              'approver': approver,
            }),
          )
          .then((onValue) {
            controller.add((e, true));
          })
          .catchError((onError) {
            controller.add((e, false));
          })
          .whenComplete(() {
            remaining--;
            if (remaining == 0) {
              controller.close();
            }
          });
    }

    return controller.stream;
  }

  Future<void> _toLogPage() async {
    final logList = await jenkins.getLogList(context, name);
    if (logList == null) {
      return;
    }
    context.push('/job/project/wms_fe_log', extra: {'obj': this, 'log_list': logList});
  }
}

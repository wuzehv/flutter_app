import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/global.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/common/loading.dart';
import 'package:provider/provider.dart';

class JenkinsShipla extends JenkinsProjectModel {
  final BuildContext context;
  final JenkinsModel jenkins;

  JenkinsShipla(this.context, this.jenkins, {required super.name});

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
                  ElevatedButton(onPressed: () => _toBuildPage(), child: Text("自定义")),
                  SizedBox(width: 7),
                  ElevatedButton.icon(
                    onPressed: () => jenkins.toLogPage(context, name),
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

  Future<void> _toBuildPage() async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    var idx = name == shiplaCt ? 7 : 5;
    try {
      final response = await jenkins.dio.post(
        '${jenkins.url}/job/$name/api/json?tree=property[parameterDefinitions[name,choices]]',
      );
      // 审核人
      List<String> a = [];
      for (var i in response.data['property'][4]['parameterDefinitions'][idx]['choices']) {
        a.add(i);
      }

      Map<String, Map<String, bool>> paramsM = {
        'env': {'tra': false, 'prod': false},
        'projects': {'shipla-oms-api': false, 'shipla-wms-api': false, 'shipla-boss-api': false},
      };
      switch (name) {
        case shiplaCt:
          paramsM['customers'] = {'shipla': false, 'redwood': false, 'wise': false, 'nateethong': false};
          break;
        case shiplaGo:
          paramsM['projects'] = {
            'open-platform-front': false,
            'open-platform-admin': false,
            'dms': false,
            'push': false,
            'ffd-cttask': false,
            'shipla-openapi-proxy': false,
          };
          break;
        case shiplaWeb:
          break;
      }

      context.push('/job/project/shipla_build', extra: {'obj': this, 'params': paramsM, 'approver': a});
    } catch (e) {
      showError('读取配置失败，请检查');
    } finally {
      loader.hide();
    }
  }

  Stream<bool> doBuild(
    BuildContext context,
    List<String> projectList,
    List<String> envList,
    List<String> customerList,
    String branch,
    String goBranch,
    String approver,
  ) {
    final controller = StreamController<bool>();
    int remaining = 1;

    var formData = FormData();
    for (var p in projectList) {
      formData.fields.add(MapEntry('PROJECTS', p));
    }
    for (var e in envList) {
      formData.fields.add(MapEntry('ENVIRONMENTS', e));
    }
    for (var c in customerList) {
      formData.fields.add(MapEntry('CUSTOMERS', c));
    }

    formData.fields.addAll([
      MapEntry('COUNTRIES', 'th'),
      MapEntry('CT_TASK_AGENT_BRANCH', goBranch),
      MapEntry('DEPLOY_BY', 'branch'),
      MapEntry('BRANCH_OR_DOCKER_IMAGE_TAG', branch),
      MapEntry('APPROVER', approver),
    ]);

    final body = formData.fields.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');

    jenkins.dio
        .post('${jenkins.url}/job/$name/buildWithParameters', data: body)
        .then((onValue) {
          controller.add(true);
        })
        .catchError((onError) {
          controller.add(false);
        })
        .whenComplete(() {
          remaining--;
          if (remaining == 0) {
            controller.close();
          }
        });

    return controller.stream;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/pages/jenkins.dart';
import 'package:dio/dio.dart';
import 'package:oktoast/oktoast.dart';

class JenkinsJob extends StatefulWidget {
  final Jenkins jenkins;

  const JenkinsJob({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsJobState();
}

class _JenkinsJobState extends State<JenkinsJob> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.remark)),
      body: ListView(
        children: (widget.jenkins.jobs ?? []).map<Widget>((job) {
          return ListTile(
            title: Text(job),
            onTap: () async {
              try {
                await widget.jenkins.getProjectList(job);
                Navigator.pushNamed(context, 'jenkins_project', arguments: widget.jenkins);
              } catch (e) {
                showError('请求失败，请检查网络和配置信息');
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

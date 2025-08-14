import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/screens/jenkins.dart';

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
                context.push('/job/project', extra: widget.jenkins);
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

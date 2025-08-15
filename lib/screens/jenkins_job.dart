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

class _JenkinsJobState extends State<JenkinsJob> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Consumer<JenkinsJobProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.jobs.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(provider.jobs[index].name),
                onTap: () async {
                  try {
                    await context
                        .read<JenkinsProjectProvider>()
                        .setJenkins(provider.currentJenkins!)
                        .fetchProjects(provider.jobs[index].name);
                    context.push('/job/project', extra: provider.jobs[index].name);
                  } catch (e) {
                    showError('请求失败，请检查网络和配置信息');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

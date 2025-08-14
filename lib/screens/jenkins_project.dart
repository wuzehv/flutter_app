import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/screens/jenkins.dart';

class JenkinsProject extends StatefulWidget {
  final Jenkins jenkins;

  const JenkinsProject({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsProjectState();
}

class _JenkinsProjectState extends State<JenkinsProject> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.remark)),
      body: ListView(
        children: (widget.jenkins.projects ?? []).map<Widget>((project) {
          return ExpansionTile(
            title: Text(project),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => widget.jenkins.toProjectPage(context, project, 'tra'),
                            child: Text("tra"),
                          ),
                          SizedBox(width: 7),
                          ElevatedButton(
                            onPressed: () => widget.jenkins.toProjectPage(context, project, 'pro'),
                            child: Text("pro"),
                          ),
                          SizedBox(width: 7),
                          ElevatedButton(
                            onPressed: () => widget.jenkins.toProjectPage(context, project, 'customize'),
                            child: Text("自定义"),
                          ),
                          SizedBox(width: 7),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!widget.jenkins.checkProjectImpl(project)) {
                                showError('当前项目未实现');
                                return;
                              }
                              try {
                                await widget.jenkins.getProjectBuildLog(project);
                                context.push('/job/project/log', extra: widget.jenkins);
                              } catch (e) {
                                print(e);
                                showError('请求失败，请检查网络和配置信息');
                              }
                            },
                            icon: Icon(Icons.playlist_add_check_outlined),
                            label: Text("审核"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

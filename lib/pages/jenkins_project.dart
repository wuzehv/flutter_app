import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/pages/jenkins.dart';

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
                          ElevatedButton(onPressed: () => widget.jenkins.toProjectPage(context, project, 'tra'), child: Text("tra")),
                          SizedBox(width: 7),
                          ElevatedButton(onPressed: () => widget.jenkins.toProjectPage(context, project, 'pro'), child: Text("pro")),
                          SizedBox(width: 7),
                          ElevatedButton(
                            onPressed: () => widget.jenkins.toProjectPage(context, project, 'customize'),
                            child: Text("自定义"),
                          ),
                          SizedBox(width: 7),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await widget.jenkins.getProjectBuildLog(project);
                                Navigator.pushNamed(context, 'jenkins_project_build_log', arguments: widget.jenkins);
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/pages/jenkins.dart';

class JenkinsProjectBuildLog extends StatefulWidget {
  final Jenkins jenkins;

  const JenkinsProjectBuildLog({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsProjectBuildLogState();
}

class _JenkinsProjectBuildLogState extends State<JenkinsProjectBuildLog> {
  Map<String, List<Widget>> _childrenMap = {};

  Future<void> _loadChildren(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    final tmp = await widget.jenkins.getProjectBuildDetail(id);
    Navigator.of(context).pop();
    setState(() {
      var m = tmp['list']
          .map<Widget>(
            (child) => ListTile(title: Text(child), dense: true, visualDensity: VisualDensity(horizontal: 0, vertical: -4)),
          )
          .toList();
      if (tmp['proceedUrl'] != null) {
        m.add(
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  widget.jenkins.auditBuild(tmp['proceedUrl']);
                },
                label: Icon(Icons.check, color: Colors.green),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.jenkins.auditBuild(tmp['abortUrl']);
                },
                label: Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        );
      }

      _childrenMap[id] = m;
    });
  }

  Future<void> _loadList() async {
    await widget.jenkins.getProjectBuildLog(widget.jenkins.project!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.project!)),
      body: ListView(
        children: (widget.jenkins.projectBuildLog ?? []).map<Widget>((project) {
          late Icon i;
          if (project['result'] == 'SUCCESS') {
            i = Icon(Icons.circle, color: Colors.green);
          } else if (project['result'] == 'ABORTED') {
            i = Icon(Icons.circle, color: Colors.grey);
          } else {
            i = Icon(Icons.radio_button_unchecked, color: Colors.blue);
          }

          return ExpansionTile(
            leading: i,
            title: Text(DateTime.fromMillisecondsSinceEpoch(project['timestamp']).toString()),
            onExpansionChanged: (bool expanded) async {
              await _loadChildren(project['id'].toString());
            },
            children: _childrenMap[project['id'].toString()] ?? [],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'refresh',
        onPressed: _loadList,
        tooltip: '刷新',
        shape: CircleBorder(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

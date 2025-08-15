import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/screens/jenkins.dart';

class WmsBeLog extends StatefulWidget {
  final Jenkins jenkins;

  const WmsBeLog({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _WmsBeLogState();
}

class _WmsBeLogState extends State<WmsBeLog> {
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
    context.pop();
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
              SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label: Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (content) {
                      return AlertDialog(
                        content: Text("确认取消任务吗?"),
                        actions: <Widget>[
                          TextButton(child: Text("取消"), onPressed: () => context.pop()),
                          TextButton(
                            child: Text("确认"),
                            onPressed: () {
                              widget.jenkins.auditBuild(tmp['abortUrl']);
                              context.pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (content) {
                      return AlertDialog(
                        content: Text("确认通过任务吗?"),
                        actions: <Widget>[
                          TextButton(child: Text("取消"), onPressed: () => context.pop()),
                          TextButton(
                            child: Text("确认"),
                            onPressed: () {
                              widget.jenkins.auditBuild(tmp['proceedUrl']);
                              context.pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                label: Icon(Icons.check, color: Colors.white),
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
            title: Text(
              '【${project['actions'][0]['parameters'][1]['value']}】${project['actions'][0]['parameters'][0]['value']} by ${project['actions'][1]['causes'][0]['userName']}',
            ),
            subtitle: Text(
              DateTime.fromMillisecondsSinceEpoch(project['timestamp']).toString(),
              style: TextStyle(color: Colors.grey, fontSize: 13.5),
            ),
            onExpansionChanged: (bool expanded) async {
              if (expanded) {
                await _loadChildren(project['id'].toString());
              }
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

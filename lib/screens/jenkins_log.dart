import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/loading_icon.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/common/loading.dart';
import 'package:provider/provider.dart';

class JenkinsLog extends StatefulWidget {
  final JenkinsModel jenkins;
  final String name;
  final List<dynamic> logList;

  const JenkinsLog({super.key, required this.jenkins, required this.logList, required this.name});

  @override
  State<StatefulWidget> createState() => _JenkinsLogState();
}

class _JenkinsLogState extends State<JenkinsLog> {
  List<Widget> _childrenMap = [];
  List<dynamic> _logList = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _logList = widget.logList;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadList();
    });
  }

  Future<void> _loadChildren(String id) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    final tmp = await widget.jenkins.getBuildDetail(widget.name, id);
    loader.hide();
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

      _childrenMap = m;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadList() async {
    showInfo('同步中......');
    final list = await widget.jenkins.getLogList(context, widget.name);
    if (list != null) {
      setState(() {
        _logList = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: ListView(
        children: _logList.map<Widget>((project) {
          late Widget i;
          if (project['result'] == 'SUCCESS') {
            i = Icon(Icons.check_circle, color: Colors.green);
          } else if (project['result'] == 'FAILURE') {
            i = Icon(Icons.cancel, color: Colors.black54);
          } else {
            i = LoadingIcon();
          }

          return ExpansionTile(
            leading: i,
            title: Text(project['title']),
            subtitle: Text(project['time'], style: TextStyle(color: Colors.grey, fontSize: 13.5)),
            onExpansionChanged: (bool expanded) async {
              if (expanded) {
                await _loadChildren(project['id']);
              }
            },
            children: _childrenMap,
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

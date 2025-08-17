import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/jenkins_wms_fe.dart';
import 'package:jenkins_app/models/loading.dart';
import 'package:provider/provider.dart';

class WmsFeLog extends StatefulWidget {
  final JenkinsWmsFe jenkins;
  final List<dynamic> logList;

  const WmsFeLog({super.key, required this.jenkins, required this.logList});

  @override
  State<StatefulWidget> createState() => _WmsFeLogState();
}

class _WmsFeLogState extends State<WmsFeLog> {
  Map<String, List<Widget>> _childrenMap = {};
  List<dynamic> _logList = [];

  @override
  void initState() {
    super.initState();
    _logList = widget.logList;
  }

  Future<void> _loadChildren(String id) async {
    final loader = context.read<LoadingProvider>();
    loader.show();
    final tmp = await widget.jenkins.jenkins.getBuildDetail(widget.jenkins.name, id);
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
                              widget.jenkins.jenkins.auditBuild(tmp['abortUrl']);
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
                              widget.jenkins.jenkins.auditBuild(tmp['proceedUrl']);
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
    final list = await widget.jenkins.jenkins.getLogList(context, widget.jenkins.name);
    if (list != null) {
      setState(() {
        _logList = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.name)),
      body: ListView(
        children: _logList.map<Widget>((project) {
          late Icon i;
          if (project['result'] == 'SUCCESS') {
            i = Icon(Icons.circle, color: Colors.green);
          } else if (project['result'] == 'FAILURE') {
            i = Icon(Icons.circle, color: Colors.grey);
          } else {
            i = Icon(Icons.radio_button_unchecked, color: Colors.blue);
          }

          return ExpansionTile(
            leading: i,
            title: Text(
              '【${project['actions'][0]['parameters'][2]['value']}】${project['actions'][0]['parameters'][1]['value']} by ${project['actions'][1]['causes'][0]['userName']}',
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

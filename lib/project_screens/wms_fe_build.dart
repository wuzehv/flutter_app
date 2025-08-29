import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins_wms_fe.dart';

class WmsFeBuild extends StatefulWidget {
  final JenkinsWmsFe jenkins;
  final String env;
  final Map<String, bool> envList;
  final List<String> approver;

  const WmsFeBuild({super.key, required this.jenkins, required this.env, required this.envList, required this.approver});

  @override
  State<StatefulWidget> createState() => _WmsFeBuildState();
}

class _WmsFeBuildState extends State<WmsFeBuild> {
  final TextEditingController _branchController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();

  String _approver = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _approver = widget.approver[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.env == 'tra') {
      _branchController.text = 'training';
    } else if (widget.env == 'pro') {
      _branchController.text = 'master';
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.name)),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              ...widget.envList.keys.map((key) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(key),
                  value: widget.envList[key],
                  onChanged: (val) {
                    setState(() {
                      widget.envList[key] = val!;
                    });
                  },
                );
              }).toList(),
              Divider(),
              ...widget.approver.map((key) {
                return RadioListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  visualDensity: VisualDensity(vertical: -4),
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Text(key),
                  value: key,
                  onChanged: (val) {
                    setState(() {
                      _approver = val!;
                    });
                  },
                  groupValue: _approver,
                );
              }).toList(),
              Divider(),
              TextFormField(
                controller: _branchController,
                decoration: InputDecoration(labelText: "分支", hintText: "分支", prefixIcon: Icon(Icons.fork_right)),
                validator: (v) => v!.trim().isNotEmpty ? null : "",
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        child: Padding(padding: const EdgeInsets.all(20.0), child: Text("提交")),
                        onPressed: () async {
                          if ((_formKey.currentState as FormState).validate()) {
                            if (_approver == "") {
                              showError('必须选择审核人');
                              return;
                            }
                            List<String> envList = [];
                            var hasTra = false;
                            var hasPro = false;
                            widget.envList.forEach((k, v) {
                              if (v && k.toLowerCase().contains('tra')) {
                                hasTra = true;
                              }
                              if (v && k.toLowerCase().contains('pro')) {
                                hasPro = true;
                              }

                              if (v) {
                                envList.add(k.toString());
                              }
                            });

                            if (hasTra == hasPro) {
                              showError('请检查环境勾选，并且不能同时包含tra和pro');
                              return;
                            }

                            showInfo('开始提交，请等待');
                            var all = true;
                            await for (final (env, success) in widget.jenkins.doBuild(
                              context,
                              envList,
                              _approver,
                              _branchController.text,
                            )) {
                              if (!success) {
                                all = false;
                              } else {
                                setState(() {
                                  widget.envList[env] = !success;
                                });
                              }
                            }

                            if (!all) {
                              showError('提交失败，请尝试重新提交');
                            } else {
                              await Future.delayed(Duration(milliseconds: 1100));
                              showSucc('提交成功');
                              widget.jenkins.jenkins.toLogPage(context, widget.jenkins.name, false);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

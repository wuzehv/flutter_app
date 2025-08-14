import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/screens/jenkins.dart';

class JenkinsBuildWmsBe extends StatefulWidget {
  final Jenkins jenkins;

  const JenkinsBuildWmsBe({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsBuildWmsBeState();
}

class _JenkinsBuildWmsBeState extends State<JenkinsBuildWmsBe> {
  final TextEditingController _branchController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();

  bool _switchSelected = false;
  Map<String, bool> _envCheckboxes = {};
  List<String> _approverCheckboxes = [];
  String _approver = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final tmp = await widget.jenkins.getWmsBeDetail();
    setState(() {
      _envCheckboxes = tmp['env'];
      _approverCheckboxes = tmp['approver'];
      _approver = _approverCheckboxes[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jenkins.env == 'tra') {
      _branchController.text = 'training';
    } else if (widget.jenkins.env == 'pro') {
      _branchController.text = 'master';
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.project!)),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text('是否安装composer'),
                  value: _switchSelected,
                  onChanged: (value) {
                    //重新构建页面
                    setState(() {
                      _switchSelected = value;
                    });
                  },
                ),
                Divider(),
                ..._envCheckboxes.keys.map((key) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    visualDensity: VisualDensity(vertical: -4),
                    title: Text(key),
                    value: _envCheckboxes[key],
                    onChanged: (val) {
                      setState(() {
                        _envCheckboxes[key] = val!;
                      });
                    },
                  );
                }).toList(),
                Divider(),
                ..._approverCheckboxes.map((key) {
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
                              _envCheckboxes.forEach((k, v) {
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
                                showError('请检查环境，不能同时包含tra和pro');
                                return;
                              }

                              showInfo('开始提交，请等待');
                              var all = true;
                              await for (final (env, success) in widget.jenkins.buildWmsBe(
                                context,
                                hasPro,
                                _switchSelected,
                                envList,
                                _approver,
                                _branchController.text,
                              )) {
                                if (!success) {
                                  all = false;
                                } else {
                                  setState(() {
                                    _envCheckboxes[env] = !success;
                                  });
                                }
                              }

                              if (!all) {
                                showSucc('提交失败，请尝试重新提交');
                              } else {
                                await Future.delayed(Duration(milliseconds: 1100));
                                showSucc('提交成功');
                                context.pop();
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
      ),
    );
  }
}

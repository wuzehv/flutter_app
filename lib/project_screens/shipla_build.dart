import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/global.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins_shipla.dart';

class ShiplaBuild extends StatefulWidget {
  final JenkinsShipla jenkins;
  final List<String> approver;
  final Map<String, Map<String, bool>> params;

  const ShiplaBuild({super.key, required this.jenkins, required this.approver, required this.params});

  @override
  State<StatefulWidget> createState() => _ShiplaBuildState();
}

class _ShiplaBuildState extends State<ShiplaBuild> {
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _goBranchController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();
  String _approver = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _branchController.text = 'master';
      _goBranchController.text = 'master';
      _approver = widget.approver[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jenkins.name)),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              ...widget.params['projects']!.keys.map((key) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(key),
                  value: widget.params['projects']![key],
                  onChanged: (val) {
                    setState(() {
                      widget.params['projects']![key] = val!;
                    });
                  },
                );
              }).toList(),
              Divider(),
              ...widget.params['env']!.keys.map((key) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(key),
                  value: widget.params['env']![key],
                  onChanged: (val) {
                    setState(() {
                      widget.params['env']![key] = val!;
                    });
                  },
                );
              }).toList(),
              Divider(),
              if (widget.jenkins.name == shiplaCt) ...<Widget>[
                ...widget.params['customers']!.keys.map((key) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    visualDensity: VisualDensity(vertical: -4),
                    title: Text(key),
                    value: widget.params['customers']![key],
                    onChanged: (val) {
                      setState(() {
                        widget.params['customers']![key] = val!;
                      });
                    },
                  );
                }).toList(),
                Divider(),
                TextFormField(
                  controller: _goBranchController,
                  decoration: InputDecoration(labelText: "cttask分支", hintText: "cttask分支", prefixIcon: Icon(Icons.fork_right)),
                  validator: (v) => v!.trim().isNotEmpty ? null : "",
                ),
              ],
              TextFormField(
                controller: _branchController,
                decoration: InputDecoration(labelText: "分支", hintText: "分支", prefixIcon: Icon(Icons.fork_right)),
                validator: (v) => v!.trim().isNotEmpty ? null : "",
              ),
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
                            widget.params['env']!.forEach((k, v) {
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

                            if (((widget.params['customers'] ?? {})['shipla'] ?? false) && hasPro) {
                              showError('生产环境不能选择shipla');
                              return;
                            }

                            if ((widget.params['customers'] ?? {}).isNotEmpty &&
                                !((widget.params['customers'] ?? {})['shipla'] ?? false) &&
                                hasTra) {
                              showError('tra环境只能选择shipla');
                              return;
                            }

                            final projectList = widget.params['projects']!.entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .toList();

                            final customerList = (widget.params['customers'] ?? {}).entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .toList();

                            showInfo('开始提交，请等待');
                            var all = true;
                            await for (final success in widget.jenkins.doBuild(
                              context,
                              projectList,
                              envList,
                              customerList,
                              _branchController.text,
                              _goBranchController.text,
                              _approver,
                            )) {
                              if (!success) {
                                all = false;
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

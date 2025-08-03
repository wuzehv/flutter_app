import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/pages/jenkins.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JenkinsConfig extends StatefulWidget {
  const JenkinsConfig({super.key});

  @override
  State<StatefulWidget> createState() => _JenkinsConfigState();
}

class _JenkinsConfigState extends State<JenkinsConfig> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  String? _id;
  final GlobalKey _formKey = GlobalKey<FormState>();

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    final jenkinsObj = ModalRoute.of(context)?.settings.arguments;
    if (jenkinsObj != null) {
      final jenkins = jenkinsObj as Jenkins;
      _urlController.text = jenkins.url;
      _remarkController.text = jenkins.remark;
      _userController.text = jenkins.user;
      _tokenController.text = jenkins.token;
      _id = jenkins.id;
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              autofocus: true,
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "地址",
                hintText: "jenkins服务地址",
                prefixIcon: Icon(Icons.link),
              ),
              validator: (v) {
                final uri = Uri.tryParse(v ?? '');
                return (uri == null || uri.host.isEmpty || uri.scheme.isEmpty)
                    ? 'url不合法'
                    : null;
              },
            ),
            TextFormField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: "用户名",
                hintText: "jenkins登录用户名",
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: "Token",
                hintText: "jenkins用户Token，不是密码",
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            TextFormField(
              autofocus: true,
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: "备注",
                hintText: "备注",
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text("保存"),
                      ),
                      onPressed: () {
                        if ((_formKey.currentState as FormState).validate()) {
                          // TODO 发请求测试一下
                          var j = Jenkins(
                            remark: _remarkController.text,
                            url: _urlController.text,
                            user: _userController.text,
                            token: _tokenController.text,
                            id: _id ?? getRandomString(10),
                          );
                          print(j);
                          if (_id != null) {
                            JenkinsStore.remove(_id!);
                          }
                          JenkinsStore.add(j.id!, j);
                          Navigator.pushReplacementNamed(context, '/');
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
    );
  }
}

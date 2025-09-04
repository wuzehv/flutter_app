import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

class JenkinsConfig extends StatefulWidget {
  final JenkinsModel? jenkins;

  const JenkinsConfig({super.key, this.jenkins});

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

  @override
  Widget build(BuildContext context) {
    final jenkins = widget.jenkins;
    if (jenkins != null) {
      _urlController.text = jenkins.url;
      _remarkController.text = jenkins.remark;
      _userController.text = jenkins.user;
      _tokenController.text = jenkins.token;
      _id = jenkins.id;
    }

    return Scaffold(
      appBar: AppBar(title: Text('配置管理')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: <Widget>[
            TextFormField(
              autofocus: true,
              controller: _urlController,
              decoration: InputDecoration(labelText: "地址", hintText: "jenkins服务地址", prefixIcon: Icon(Icons.link)),
              validator: (v) {
                final uri = Uri.tryParse(v ?? '');
                return (uri == null || uri.host.isEmpty || uri.scheme.isEmpty) ? 'url不合法' : null;
              },
            ),
            TextFormField(
              controller: _userController,
              decoration: InputDecoration(labelText: "用户名", hintText: "jenkins登录用户名", prefixIcon: Icon(Icons.person)),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            if (_id == null)
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(labelText: "Token", hintText: "jenkins用户Token，不是密码", prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.trim().isNotEmpty ? null : "",
              ),
            TextFormField(
              controller: _remarkController,
              decoration: InputDecoration(labelText: "备注", hintText: "备注", prefixIcon: Icon(Icons.description_outlined)),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      child: Padding(padding: const EdgeInsets.all(20.0), child: Text("保存")),
                      onPressed: () async {
                        if ((_formKey.currentState as FormState).validate()) {
                          var j = JenkinsModel(
                            remark: _remarkController.text.trim(),
                            url: trimEndingChars(_urlController.text, "/ "),
                            user: _userController.text.trim(),
                            token: _tokenController.text.trim(),
                            id: _id,
                          );
                          await context.read<JenkinsProvider>().save(j);
                          context.pop();
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

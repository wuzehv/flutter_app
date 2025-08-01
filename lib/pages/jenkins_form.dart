import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

class JenkinsConfig extends StatefulWidget {
  const JenkinsConfig({super.key});

  @override
  State<StatefulWidget> createState() => _JenkinsConfigState();
}

class _JenkinsConfigState extends State<JenkinsConfig> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
            obscureText: true,
            validator: (v) => v!.trim().isNotEmpty ? null : "",
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("添加"),
                    ),
                    onPressed: () {
                      showToastWidget(
                        Text('hello oktoast', textAlign: TextAlign.right),
                      );
                      if ((_formKey.currentState as FormState).validate()) {
                        //验证通过提交数据
                        print(
                          _userController.text +
                              _urlController.text +
                              _tokenController.text,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

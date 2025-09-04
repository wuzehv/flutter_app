import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:provider/provider.dart';

class CodeUpConfig extends StatefulWidget {
  final CodeUpModel? codeUp;

  const CodeUpConfig({super.key, this.codeUp});

  @override
  State<StatefulWidget> createState() => _CodeUpConfigState();
}

class _CodeUpConfigState extends State<CodeUpConfig> {
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final jenkins = widget.codeUp;
    if (jenkins != null) {
      _orgController.text = jenkins.orgId;
      _remarkController.text = jenkins.remark;
      _tokenController.text = jenkins.token;
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
              controller: _orgController,
              decoration: InputDecoration(labelText: "组织ID", hintText: "组织ID", prefixIcon: Icon(Icons.business)),
              validator: (v) => v!.trim().isNotEmpty ? null : "",
            ),
            if (_tokenController.text.isEmpty) ...[
              Text('Token权限配置说明：', style: TextStyle(fontSize: 13)),
              Text('代码管理 > 代码仓库 > [只读]', style: TextStyle(color: Colors.red, fontSize: 13)),
              Text('代码管理 > 和并请求 > [读写]', style: TextStyle(color: Colors.red, fontSize: 13)),
              Text('请勿申请多余权限！！！', style: TextStyle(color: Colors.red, fontSize: 13)),
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(labelText: "Token", hintText: "用户Token", prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.trim().isNotEmpty ? null : "",
              ),
            ],
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
                          var j = CodeUpModel(
                            remark: _remarkController.text.trim(),
                            orgId: _orgController.text.trim(),
                            token: _tokenController.text.trim(),
                          );
                          await context.read<CodeUpProvider>().save(j);
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

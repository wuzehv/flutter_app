import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

class JenkinsConfig extends StatefulWidget {
  final JenkinsModel? jenkins;

  const JenkinsConfig({super.key, this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsConfigState();
}

class _JenkinsConfigState extends State<JenkinsConfig> {
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _id;

  @override
  void initState() {
    super.initState();
    final jenkins = widget.jenkins;
    if (jenkins != null) {
      _remarkController.text = jenkins.remark;
      _userController.text = jenkins.user;
      _tokenController.text = jenkins.token;
      _id = jenkins.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.jenkins != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑 Jenkins 配置' : '添加 Jenkins 配置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 用户名输入
              _buildTextField(
                controller: _userController,
                label: '用户名',
                hint: '请输入 Jenkins 登录用户名',
                icon: Icons.person_outline,
                validator: (v) => v!.trim().isNotEmpty ? null : '用户名不能为空',
              ),
              const SizedBox(height: 16),

              // Token 输入（仅新建时显示）
              if (!isEditing) ...[
                _buildTextField(
                  controller: _tokenController,
                  label: 'Token',
                  hint: '请输入 Jenkins 用户 Token',
                  icon: Icons.lock_outline,
                  validator: (v) => v!.trim().isNotEmpty ? null : 'Token 不能为空',
                ),
                const SizedBox(height: 16),
              ],

              // 备注输入
              _buildTextField(
                controller: _remarkController,
                label: '备注',
                hint: '请输入配置备注，如：生产环境',
                icon: Icons.description_outlined,
                validator: (v) => v!.trim().isNotEmpty ? null : '备注不能为空',
              ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('保存配置', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      var j = JenkinsModel(
        remark: _remarkController.text.trim(),
        url: '',
        user: _userController.text.trim(),
        token: _tokenController.text.trim(),
        id: _id,
      );
      await context.read<JenkinsProvider>().save(j);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _userController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}

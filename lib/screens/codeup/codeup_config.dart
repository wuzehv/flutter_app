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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final codeUp = widget.codeUp;
    if (codeUp != null) {
      _orgController.text = codeUp.orgId;
      _remarkController.text = codeUp.remark;
      _tokenController.text = codeUp.token;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.codeUp != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑 CodeUp 配置' : '添加 CodeUp 配置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 组织 ID 输入
              _buildTextField(
                controller: _orgController,
                label: '组织 ID',
                hint: '请输入 CodeUp 组织 ID',
                icon: Icons.business,
                validator: (v) => v!.trim().isNotEmpty ? null : '组织 ID 不能为空',
              ),
              const SizedBox(height: 16),

              // Token 输入（仅新建时显示）
              if (!isEditing) ...[
                _buildTextField(
                  controller: _tokenController,
                  label: '个人访问令牌 (Token)',
                  hint: '请输入个人访问令牌',
                  icon: Icons.lock_outline,
                  validator: (v) => v!.trim().isNotEmpty ? null : 'Token 不能为空',
                ),
                const SizedBox(height: 16),

                // 权限说明卡片
                _buildPermissionCard(),
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

  /// 构建权限说明卡片（紧凑版）
  Widget _buildPermissionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Token 权限配置说明',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          // 权限列表
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionItem(
                  title: '代码仓库',
                  permission: '只读',
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                _buildPermissionItem(
                  title: '提交',
                  permission: '只读',
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                _buildPermissionItem(
                  title: '分支',
                  permission: '只读',
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                _buildPermissionItem(
                  title: '代码比较',
                  permission: '只读',
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                _buildPermissionItem(
                  title: '文件',
                  permission: '只读',
                  color: Colors.green,
                ),
                const SizedBox(height: 6),
                _buildPermissionItem(
                  title: '合并请求',
                  permission: '读写',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          // 警告提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '请勿申请多余权限，遵循最小权限原则',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String permission,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '代码管理 > $title',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
          ),
          child: Text(
            permission,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      var j = CodeUpModel(
        remark: _remarkController.text.trim(),
        orgId: _orgController.text.trim(),
        token: _tokenController.text.trim(),
      );
      await context.read<CodeUpProvider>().save(j);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _orgController.dispose();
    _remarkController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}

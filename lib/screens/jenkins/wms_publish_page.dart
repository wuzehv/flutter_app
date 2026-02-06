import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/jenkins/widgets/choice_selector.dart';
import 'package:provider/provider.dart';

class WmsPublishPage extends StatefulWidget {
  final JenkinsModel jenkins;
  final String projectName;

  const WmsPublishPage({super.key, required this.jenkins, required this.projectName});

  @override
  State<WmsPublishPage> createState() => _WmsPublishPageState();
}

class _WmsPublishPageState extends State<WmsPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _ctBranchController = TextEditingController();
  
  // 对应Wms结构体的字段
  List<String> _selectedCountries = [];
  List<String> _selectedOpTypes = [];
  List<String> _selectedProjects = [];
  String _env = 'pro'; // 环境默认选中pro
  String _branch = 'master'; // PHP分支根据环境智能填充
  String _ctBranch = 'master'; // GO分支默认填充master
  String _approver = '';
  
  // 可选项数据（这些通常会从后端获取）
  List<String> _countries = ['CN', 'US', 'UK', 'JP']; // 示例数据
  List<String> _opTypes = ['web', 'ct']; // 示例数据
  List<String> _projects = ['project_a', 'project_b', 'project_c']; // 示例数据
  List<String> _envs = ['tra', 'pro']; // 环境选项
  List<String> _approvers = []; // 审核人列表

  @override
  void initState() {
    super.initState();
    // 初始化控制器值
    _branchController.text = _branch;
    _ctBranchController.text = _ctBranch;
    // 初始化时加载审核人列表
    _loadApprovers();
  }

  @override
  void dispose() {
    _branchController.dispose();
    _ctBranchController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovers() async {
    // 这里应该从API获取审核人列表
    // 暂时使用示例数据
    setState(() {
      _approvers = ['admin', 'manager', 'developer'];
      if (_approvers.isNotEmpty) {
        _approver = _approvers[0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} - WMS发布'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 国家列表选择（增加全选功能）
                ChoiceSelector(
                  title: '国家列表',
                  options: _countries,
                  selectedValues: _selectedCountries,
                  showSelectAll: true, // 启用全选功能
                  onSelectionChanged: (country) {
                    setState(() {
                      if (_selectedCountries.contains(country)) {
                        _selectedCountries.remove(country);
                      } else {
                        _selectedCountries.add(country);
                      }
                    });
                  },
                  onSelectAll: (selectedCountries) {
                    setState(() {
                      _selectedCountries = selectedCountries;
                    });
                  },
                ),
                SizedBox(height: 16),

                // 操作类型选择
                ChoiceSelector(
                  title: '操作类型',
                  options: _opTypes,
                  selectedValues: _selectedOpTypes,
                  onSelectionChanged: (opType) {
                    setState(() {
                      if (_selectedOpTypes.contains(opType)) {
                        _selectedOpTypes.remove(opType);
                      } else {
                        _selectedOpTypes.add(opType);
                      }
                    });
                  },
                ),
                SizedBox(height: 16),

                // 项目列表选择
                ChoiceSelector(
                  title: '项目列表',
                  options: _projects,
                  selectedValues: _selectedProjects,
                  onSelectionChanged: (project) {
                    setState(() {
                      if (_selectedProjects.contains(project)) {
                        _selectedProjects.remove(project);
                      } else {
                        _selectedProjects.add(project);
                      }
                    });
                  },
                ),
                SizedBox(height: 16),

                // 环境选择（改为复选样式）
                ChoiceSelector(
                  title: '环境',
                  options: _envs,
                  selectedValues: [], // 多选模式下使用
                  selectedValue: _env, // 单选模式下使用
                  isMultiSelect: false, // 单选模式
                  onSelectionChanged: (env) {
                    setState(() {
                      _env = env;
                      // 根据环境智能填充PHP分支
                      if (env == 'tra') {
                        _branch = 'training';
                      } else if (env == 'pro') {
                        _branch = 'master';
                      }
                      // 同时更新控制器
                      _branchController.text = _branch;
                    });
                  },
                ),
                SizedBox(height: 16),

                // PHP分支输入
                TextFormField(
                  controller: _branchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'PHP分支 *',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 统一内边距
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入PHP分支';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _branch = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // GO分支输入
                TextFormField(
                  controller: _ctBranchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'GO分支 *',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 统一内边距
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入GO分支';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _ctBranch = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // 审核人选择（改为复选样式）
                ChoiceSelector(
                  title: '审核人',
                  options: _approvers,
                  selectedValues: [], // 多选模式下使用
                  selectedValue: _approver, // 单选模式下使用
                  isMultiSelect: false, // 单选模式
                  onSelectionChanged: (approver) {
                    setState(() {
                      _approver = approver;
                    });
                  },
                ),
                SizedBox(height: 24),

                // 提交按钮
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                      child: Text('提交发布', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 验证必填字段
      if (_selectedCountries.isEmpty) {
        showError('请选择国家列表');
        return;
      }
      if (_selectedOpTypes.isEmpty) {
        showError('请选择操作类型');
        return;
      }
      if (_selectedProjects.isEmpty) {
        showError('请选择项目列表');
        return;
      }
      if (_env.isEmpty) {
        showError('请选择环境');
        return;
      }
      if (_branch.isEmpty) {
        showError('请输入PHP分支');
        return;
      }
      if (_ctBranch.isEmpty) {
        showError('请输入GO分支');
        return;
      }
      if (_approver.isEmpty) {
        showError('请选择审核人');
        return;
      }

      // 显示加载状态
      showInfo('正在提交发布请求...');
      
      try {
        // 调用后端API进行发布
        // 这里需要根据实际API接口调整
        final response = await widget.jenkins.dio.post(
          '${widget.jenkins.url}/wms/publish', // 假设的API路径
          data: {
            'countries': _selectedCountries,
            'op_type': _selectedOpTypes,
            'projects': _selectedProjects,
            'env': _env,
            'branch': _branch,
            'ct_branch': _ctBranch,
            'approver': _approver,
          },
        );
        
        if (response.statusCode == 200) {
          showSucc('发布请求提交成功');
          Navigator.pop(context); // 返回上一页
        } else {
          showError('发布请求提交失败');
        }
      } catch (e) {
        showError('发布请求提交失败: ${e.toString()}');
      }
    }
  }
}
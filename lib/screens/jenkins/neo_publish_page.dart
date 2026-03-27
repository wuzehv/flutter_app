import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/common/approver_utils.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/jenkins/widgets/choice_selector.dart';
import 'package:provider/provider.dart';

class NeoPublishPage extends StatefulWidget {
  final JenkinsModel jenkins;
  final String projectName;
  final String? initialBranch;

  const NeoPublishPage({
    super.key,
    required this.jenkins,
    required this.projectName,
    this.initialBranch,
  });

  @override
  State<NeoPublishPage> createState() => _NeoPublishPageState();
}

class _NeoPublishPageState extends State<NeoPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _ctBranchController = TextEditingController();
  
  // 对应Neo结构体的字段
  List<String> _selectedOpTypes = ['web']; // 操作类型默认选中web
  List<String> _selectedProjects = [];
  String _env = 'pro'; // 环境默认选中pro
  String _branch = 'master'; // PHP分支根据环境智能填充
  String _ctBranch = 'master'; // GO分支默认填充master
  String _approver = ''; // 审核人将在数据加载后设置为第一个
  
  // 动态获取的数据
  List<String> _opTypes = ['web', 'ct']; // 操作类型固定值
  List<String> _projects = [];
  List<String> _envs = ['pro']; // 环境选项保持不变
  List<String> _approvers = []; // 从API获取审核人列表
  List<String> _sortedApprovers = []; // 排序后的审核人列表

  @override
  void initState() {
    super.initState();
    // 如果有传入的初始分支，只替换 PHP 分支
    if (widget.initialBranch != null && widget.initialBranch!.isNotEmpty) {
      _branch = widget.initialBranch!;
    }
    // 初始化控制器值
    _branchController.text = _branch;
    _ctBranchController.text = _ctBranch;
    // 初始化时加载构建参数
    _loadBuildParams();
  }

  @override
  void dispose() {
    _branchController.dispose();
    _ctBranchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildParams() async {
    try {
      final data = await widget.jenkins.getBuildParams(widget.projectName);
      
      setState(() {
        // 从API响应中提取数据
        _projects = List<String>.from(data['projects'] ?? []);
        _approvers = List<String>.from(data['approvers'] ?? []);
        
        // 对审核人进行排序（领导置顶）
        _sortedApprovers = ApproverUtils.sortApproversWithLeadersFirst(
          _approvers, 
          ApproverUtils.DEFAULT_LEADERS
        );
        
        // 设置默认审核人
        if (_sortedApprovers.isNotEmpty) {
          _approver = _sortedApprovers[0];
        }
      });
    } catch (e) {
      showError('获取构建参数失败: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} - 发布'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 环境选择（改为复选样式）- 移到最上面
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
                      if (env == 'pro') {
                        _branch = 'master';
                      }
                      // 同时更新控制器
                      _branchController.text = _branch;
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

                // PHP分支输入
                TextFormField(
                  controller: _branchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'PHP分支 *',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                  options: _sortedApprovers,
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

      // 构造请求数据
      final requestData = {
        'op_type': _selectedOpTypes,
        'projects': _selectedProjects,
        'env': _env,
        'branch': _branch,
        'ct_branch': _ctBranch,
        'approver': _approver,
      };

      // 调用通用发布方法
      bool success = await _publish('/open/build_neo', requestData);

      if (success) {
        Navigator.pop(context); // 返回上一页
      }
    }
  }

  /// 通用发布方法
  /// [apiPath] API路径，如 '/neo/publish'
  /// [requestData] 请求数据
  Future<bool> _publish(String apiPath, Map<String, dynamic> requestData) async {
    return await widget.jenkins.publish(apiPath, requestData, context);
  }
}

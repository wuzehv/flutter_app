import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/common/approver_utils.dart';
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
  List<String> _selectedOpTypes = ['web']; // 操作类型默认选中web
  List<String> _selectedProjects = [];
  String _env = 'pro'; // 环境默认选中pro
  String _branch = 'master'; // PHP分支根据环境智能填充
  String _ctBranch = 'master'; // GO分支默认填充master
  String _approver = '';

  // 动态获取的数据
  List<String> _countries = [];
  List<String> _opTypes = ['web', 'ct']; // 操作类型固定值
  List<String> _projects = [];
  List<String> _envs = ['tra', 'pro']; // 环境选项保持不变
  List<String> _approvers = [];

  // K8s相关数据
  List<String> _k8sTra = [];
  List<String> _k8sPro = [];

  // 每个项目对应的审核人列表（从API获取）
  Map<String, List<String>> _projectApprovers = {};

  // SCM项目审核人映射 {中文名: 英文名}
  Map<String, String> _scmApproversMap = {};

  // BOSS项目审核人映射 {中文名: 英文名}
  Map<String, String> _bossApproversMap = {};

  // WMS项目审核人映射 {中文名: 英文名}
  Map<String, String> _wmsApproversMap = {};

  // 特殊国家审核人映射（与wms相同）
  Map<String, String> _specialCountryApproversMap = {};

  // 用于显示的中文审核人列表
  List<String> _displayApprovers = [];

  @override
  void initState() {
    super.initState();
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
        _countries = List<String>.from(data['countries'] ?? []);
        _projects = List<String>.from(data['projects'] ?? []);

        // 获取k8s国家列表
        _k8sTra = List<String>.from(data['k8s_tra'] ?? []);
        _k8sPro = List<String>.from(data['k8s_pro'] ?? []);

        // 审核人相关数据 - 处理map结构 {中文名: 英文名}
        _scmApproversMap = Map<String, String>.from(data['scm_approvers'] as Map<String, dynamic>? ?? {});
        _bossApproversMap = Map<String, String>.from(data['boss_approvers'] as Map<String, dynamic>? ?? {});
        _wmsApproversMap = Map<String, String>.from(data['wms_approvers'] as Map<String, dynamic>? ?? {});

        // 特殊国家审核人与wms相同
        _specialCountryApproversMap = Map<String, String>.from(data['wms_approvers'] as Map<String, dynamic>? ?? {});

        // 构建项目审核人映射
        _projectApprovers = {
          'scm': _scmApproversMap.values.toList(),
          'boss': _bossApproversMap.values.toList(),
          'wms': _wmsApproversMap.values.toList(),
        };

        // 计算符合条件的审核人
        _calculateQualifiedApprovers();

        // 注意：此时_selectedProjects为空，所以_displayApprovers也为空
        // 默认审核人将在用户选择项目后设置
      });
    } catch (e) {
      showError('获取构建参数失败: ${e.toString()}');
    }
  }

  // 计算符合条件的审核人
  void _calculateQualifiedApprovers() {
    if (_selectedProjects.isEmpty) {
      _approvers = [];
      _displayApprovers = [];
      return;
    }

    Set<String> qualifiedApprovers = <String>{};
    Set<String> displayApproversSet = <String>{};

    // 判断是否只选择了k8s国家
    bool isOnlyK8sCountries = _isOnlyK8sCountriesSelected();

    if (isOnlyK8sCountries) {
      // 只选择k8s国家的情况：使用wms_approvers
      qualifiedApprovers = Set.from(_wmsApproversMap.values);
    } else {
      // 其他情况：显示项目审核人的交集
      qualifiedApprovers = _getProjectApproverIntersection();
    }

    // 获取对应的中文显示名称
    for (var englishName in qualifiedApprovers) {
      String chineseName = _getChineseNameByEnglish(englishName);
      if (chineseName.isNotEmpty) {
        displayApproversSet.add(chineseName);
      }
    }

    // 转换为列表并排序
    _approvers = qualifiedApprovers.toList()..sort();
    _displayApprovers = displayApproversSet.toList()..sort();

    // 将领导置顶显示
    _sortApproversWithLeadersFirst();
    
    // 如果有可用审核人且还未设置默认审核人，则选中第一个
    if (_displayApprovers.isNotEmpty && _approver.isEmpty) {
      _approver = _displayApprovers[0];
    }
  }

  // 判断是否只选择了k8s国家
  bool _isOnlyK8sCountriesSelected() {
    if (_selectedCountries.isEmpty) return false;

    // 获取当前环境的k8s国家列表
    Set<String> currentK8sCountries = _getK8sCountriesForCurrentEnv();

    // 检查所选国家是否都在k8s国家列表中
    for (String country in _selectedCountries) {
      if (!currentK8sCountries.contains(country)) {
        return false; // 发现非k8s国家
      }
    }

    return true; // 所有选择的国家都是k8s国家
  }

  // 将领导置顶排序
  void _sortApproversWithLeadersFirst() {
    _displayApprovers = ApproverUtils.sortApproversWithLeadersFirst(
      _displayApprovers, 
      ApproverUtils.DEFAULT_LEADERS
    );
  }

  // 获取项目审核人交集
  Set<String> _getProjectApproverIntersection() {
    if (_selectedProjects.isEmpty) return <String>{};

    // 初始化为第一个项目的审核人列表
    Set<String> intersection = <String>{};
    String firstProject = _selectedProjects[0];

    // 根据项目名称获取对应的审核人列表
    List<String> firstProjectApprovers = _getProjectApproversByName(firstProject);
    if (firstProjectApprovers.isNotEmpty) {
      intersection.addAll(firstProjectApprovers);
    }

    // 与其他项目的审核人列表求交集
    for (int i = 1; i < _selectedProjects.length; i++) {
      String project = _selectedProjects[i];
      List<String> projectApprovers = _getProjectApproversByName(project);
      if (projectApprovers.isNotEmpty) {
        intersection = intersection.intersection(Set.from(projectApprovers));
      } else {
        // 如果某个项目没有审核人列表，则交集为空
        return <String>{};
      }
    }

    return intersection;
  }

  // 根据项目名称获取审核人列表（英文名）
  List<String> _getProjectApproversByName(String projectName) {
    // 将项目名称映射到对应的审核人列表
    if (projectName.toLowerCase().contains('scm')) {
      return _scmApproversMap.values.toList();
    } else if (projectName.toLowerCase().contains('boss')) {
      return _bossApproversMap.values.toList();
    } else if (projectName.toLowerCase().contains('wms')) {
      return _wmsApproversMap.values.toList();
    }
    return [];
  }

  // 根据英文名获取中文名
  String _getChineseNameByEnglish(String englishName) {
    // 在所有审核人map中查找对应的中文名
    if (_scmApproversMap.containsValue(englishName)) {
      return _scmApproversMap.keys.firstWhere((key) => _scmApproversMap[key] == englishName);
    }
    if (_bossApproversMap.containsValue(englishName)) {
      return _bossApproversMap.keys.firstWhere((key) => _bossApproversMap[key] == englishName);
    }
    if (_wmsApproversMap.containsValue(englishName)) {
      return _wmsApproversMap.keys.firstWhere((key) => _wmsApproversMap[key] == englishName);
    }
    return '';
  }

  // 根据环境计算当前可用国家列表
  List<String> _getCurrentCountries() {
    if (_env == 'tra') {
      // tra环境：取k8s_tra和国家列表的交集
      Set<String> k8sTraSet = Set.from(_k8sTra);
      Set<String> countriesSet = Set.from(_countries);
      Set<String> filteredCountries = k8sTraSet.intersection(countriesSet);
      return filteredCountries.toList()..sort();
    } else {
      // 其他环境：返回完整国家列表
      return _countries;
    }
  }

  // 获取当前环境对应的k8s国家集合
  Set<String> _getK8sCountriesForCurrentEnv() {
    if (_env == 'tra') {
      return Set.from(_k8sTra);
    } else if (_env == 'pro') {
      return Set.from(_k8sPro);
    } else {
      return {};
    }
  }

  // 获取WMS发布页面在当前环境下的可用国家列表
  List<String> _getFilteredCountries() {
    return _getCurrentCountries();
  }

  // 根据中文名获取英文名（用于提交）
  String _getEnglishNameByChinese(String chineseName) {
    return _scmApproversMap[chineseName] ?? _bossApproversMap[chineseName] ?? _wmsApproversMap[chineseName] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.projectName} - 发布')),
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
                  selectedValues: [],
                  // 多选模式下使用
                  selectedValue: _env,
                  // 单选模式下使用
                  isMultiSelect: false,
                  // 单选模式
                  onSelectionChanged: (env) {
                    setState(() {
                      _env = env;
                      // 根据环境智能填充PHP分支
                      if (env == 'tra') {
                        _branch = 'training';
                      } else if (env == 'pro') {
                        _branch = 'master';
                      }
                      // 环境变化时重新计算审核人
                      _calculateQualifiedApprovers();
                      // 同时更新控制器
                      _branchController.text = _branch;
                    });
                  },
                ),
                SizedBox(height: 16),

                // 国家列表选择（增加全选功能）
                ChoiceSelector(
                  title: '国家列表',
                  options: _getFilteredCountries(),
                  // 使用过滤后的国家列表
                  selectedValues: _selectedCountries,
                  showSelectAll: true,
                  // 启用全选功能
                  k8sOptions: _getK8sCountriesForCurrentEnv(),
                  // 传入当前环境的k8s国家标识
                  onSelectionChanged: (country) {
                    setState(() {
                      if (_selectedCountries.contains(country)) {
                        _selectedCountries.remove(country);
                      } else {
                        _selectedCountries.add(country);
                      }
                      // 国家选择变化时重新计算审核人
                      _calculateQualifiedApprovers();
                    });
                  },
                  onSelectAll: (selectedCountries) {
                    setState(() {
                      _selectedCountries = selectedCountries;
                      // 全选变化时重新计算审核人
                      _calculateQualifiedApprovers();
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
                      // 项目选择变化时重新计算审核人
                      _calculateQualifiedApprovers();
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
                  options: _displayApprovers,
                  // 使用中文显示列表
                  selectedValues: [],
                  // 多选模式下使用
                  selectedValue: _approver,
                  // 单选模式下使用
                  isMultiSelect: false,
                  // 单选模式
                  onSelectionChanged: (chineseApprover) {
                    setState(() {
                      // 保存中文名用于显示，提交时转换为英文名
                      _approver = chineseApprover;
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

  /// 通用发布方法
  /// [apiPath] API路径，如 '/wms/publish'
  /// [requestData] 请求数据
  Future<bool> _publish(String apiPath, Map<String, dynamic> requestData) async {
    return await widget.jenkins.publish(apiPath, requestData, context);
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

      // 构造请求数据
      final requestData = {
        'countries': _selectedCountries,
        'op_type': _selectedOpTypes,
        'projects': _selectedProjects,
        'env': _env,
        'branch': _branch,
        'ct_branch': _ctBranch,
        'approver': _getEnglishNameByChinese(_approver), // 提交英文名
      };

      // 调用通用发布方法
      bool success = await _publish('/open/build_wms', requestData);

      if (success) {
        Navigator.pop(context); // 返回上一页
      }
    }
  }
}

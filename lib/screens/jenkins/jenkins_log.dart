import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'pending_approval_item.dart';

class JenkinsLog extends StatefulWidget {
  final JenkinsModel jenkins;
  final String name;
  final List<String> searchOptions;

  const JenkinsLog({super.key, required this.jenkins, required this.name, required this.searchOptions});

  @override
  State<StatefulWidget> createState() => _JenkinsLogState();
}

class _JenkinsLogState extends State<JenkinsLog> {  String _selectedFilter = ''; // 默认选择
  List<Map<String, dynamic>> _logList = []; // 存储日志列表

  @override
  void initState() {
    _selectedFilter = widget.searchOptions[0];
    super.initState();

    // 初始化时获取项目列表
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadLogs();
      } catch (e) {
        // 错误处理
      }
    });
  }

  Future<void> _loadLogs() async {
    final logs = await widget.jenkins.getBuildList(_selectedFilter); // 使用_getSelectedFilter作为项目名称参数
    setState(() {
      _logList = logs.cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          // 下拉搜索选项
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('项目:', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    items: widget.searchOptions.map((String option) {
                      return DropdownMenuItem<String>(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                        _loadLogs(); // 当筛选条件改变时，重新加载日志
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // 发布历史列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                try {
                  await _loadLogs();
                } catch (e) {
                  // 错误处理
                }
              },
              child: ListView.builder(
                itemCount: _logList.length,
                itemBuilder: (context, index) {
                  final item = _logList[index];
                  return PendingApprovalItem(
                    item: item,
                    onReject: () {
                      // 调用审核拒绝接口
                      try {
                        // context.read<JenkinsJobProvider>().rejectSingleItem(item);
                        showInfo('已拒绝');
                      } catch (e) {
                        showError('拒绝失败');
                      }
                    },
                    onApprove: () {
                      // 调用审核通过接口
                      try {
                        // context.read<JenkinsJobProvider>().approveSingleItem(item);
                        showInfo('已通过');
                      } catch (e) {
                        showError('通过失败');
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

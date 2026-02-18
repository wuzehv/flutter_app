import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';

import 'pending_approval_item.dart';

// 自动刷新间隔常量
const int _AUTO_REFRESH_INTERVAL = 10; // 10秒

class JenkinsLog extends StatefulWidget {
  final JenkinsModel jenkins;
  final String name;
  final List<String> searchOptions;

  const JenkinsLog({super.key, required this.jenkins, required this.name, required this.searchOptions});

  @override
  State<StatefulWidget> createState() => _JenkinsLogState();
}

class _JenkinsLogState extends State<JenkinsLog> {
  String _selectedFilter = ''; // 默认选择
  List<Map<String, dynamic>> _logList = []; // 存储日志列表
  Timer? _refreshTimer; // 自动刷新定时器
  Timer? _countdownTimer; // 倒计时定时器
  bool _isAutoRefreshing = false; // 自动刷新状态
  int _secondsUntilRefresh = _AUTO_REFRESH_INTERVAL; // 距离下次刷新的秒数
  bool _isLoading = true; // 默认显示加载状态

  @override
  void initState() {
    _selectedFilter = widget.searchOptions[0];
    super.initState();

    // 初始化时获取项目列表
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadLogs();
        // 启动自动刷新定时器
        _startAutoRefresh();
      } catch (e) {
        // 静默处理初始化错误
      }
    });
  }

  Future<void> _loadLogs([bool isAutoRefresh = false]) async {
    // 自动刷新时不显示loading状态，避免闪屏
    if (!isAutoRefresh) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final logs = await widget.jenkins.getBuildList(_selectedFilter);
      if (mounted) {
        setState(() {
          _logList = logs.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // 静默处理错误
    } finally {
      if (mounted && !isAutoRefresh) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 启动自动刷新
  void _startAutoRefresh() {
    // 启动倒计时
    _startCountdown();

    _refreshTimer = Timer.periodic(Duration(seconds: _AUTO_REFRESH_INTERVAL), (timer) async {
      if (mounted) {
        setState(() {
          _isAutoRefreshing = true;
          _secondsUntilRefresh = _AUTO_REFRESH_INTERVAL; // 重置倒计时
        });

        try {
          await _loadLogs(true); // 传入true表示是自动刷新
          // 重新启动倒计时
          _startCountdown();
        } catch (e) {
          // 静默处理刷新错误
        } finally {
          if (mounted) {
            setState(() {
              _isAutoRefreshing = false;
            });
          }
        }
      }
    });
  }

  // 启动倒计时
  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsUntilRefresh = _AUTO_REFRESH_INTERVAL;

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsUntilRefresh--;
          if (_secondsUntilRefresh <= 0) {
            _secondsUntilRefresh = _AUTO_REFRESH_INTERVAL;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  // 停止自动刷新
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    // 页面销毁时停止所有定时器
    _stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          // 显示自动刷新倒计时
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Text(
              '自动刷新中，$_secondsUntilRefresh秒后刷新',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: Colors.red,
              ),
            ),
          ),
          // 显示刷新状态
          if (_isAutoRefreshing)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
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
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '加载中...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      try {
                        await _loadLogs();
                      } catch (e) {
                        // 静默处理手动刷新错误
                      }
                    },
                    child: _logList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '暂无构建记录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _logList.length,
                            itemBuilder: (context, index) {
                              final item = _logList[index];
                              return PendingApprovalItem(
                                item: item,
                                currentUser: widget.jenkins.user,
                                onReject: () {
                                  // 调用审核拒绝接口
                                  widget.jenkins.abortBuild(item["id"]);
                                },
                                onApprove: () {
                                  // 调用审核通过接口
                                  widget.jenkins.proceedBuild(item["id"]);
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
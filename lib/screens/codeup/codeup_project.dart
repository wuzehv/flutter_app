import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

import '../../common/util.dart';

class CodeUpProject extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpProject({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpProjectState();
}

class _CodeUpProjectState extends State<CodeUpProject> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _items = [];
  bool _isLoadingMore = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _items = widget.codeup.projectList;

    // 上滑动，加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !_isLoadingMore) {
        _loadData(false);
      }
    });
  }

  // 模拟加载更多数据
  Future<void> _loadData(bool init) async {
    if (init) {
      _items = [];
      _page = 0;
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    _page++;
    final pageItems = await widget.codeup.getProjectList(_page);
    setState(() {
      _items.addAll(pageItems);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.codeup.remark)),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(true),
        child: ListView.separated(
          controller: _scrollController,
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index < _items.length) {
              return ListTile(
                leading: Icon(Icons.terminal),
                title: Row(
                  children: [
                    Text(_items[index]['path'] + '/', style: TextStyle(color: Colors.grey)),
                    Text(_items[index]['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                subtitle: Text(
                  (_items[index]['desc'] == null ? '' : _items[index]['desc'] + ' · ') + "更新于 ${_items[index]['update']}",
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  widget.codeup.curProjectName = _items[index]['name'];
                  widget.codeup.curProjectId = _items[index]['id'];
                  try {
                    await widget.codeup.getProjectMrList(_items[index]['id'], 'merged');
                    context.push('/codeup/project/mr', extra: widget.codeup);
                  } catch (e) {
                    showError('请求失败，请检查网络和配置信息');
                  }
                },
              );
            } else {
              // 加载更多提示
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: _isLoadingMore ? CircularProgressIndicator() : Text("上滑加载更多")),
              );
            }
          },
          separatorBuilder: (context, index) => Divider(height: .0),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

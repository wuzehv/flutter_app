import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

import '../../common/util.dart';

class CodeUpMr extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpMr({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpMrState();
}

class _CodeUpMrState extends State<CodeUpMr> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _items = widget.codeup.projectMrList;
  }

  // 模拟加载更多数据
  Future<void> _loadData() async {
    final pageItems = await widget.codeup.getProjectMrList(widget.codeup.curProjectId, 'merged');
    setState(() {
      _items = pageItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.codeup.curProjectName)),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView.separated(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            if (_items.isNotEmpty) {
              return ListTile(
                leading: Icon(Icons.merge),
                title: Text(_items[index]['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_items[index]['source']} -> ${_items[index]['target']}'),
                    Text('${_items[index]['author']} 创建于 ${_items[index]['created']}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          label: Icon(Icons.close, color: Colors.white),
                          onPressed: () async {},
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          label: Icon(Icons.check, color: Colors.white),
                          onPressed: () async {},
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              // 加载更多提示
              return Center(child: Text('无数据'));
            }
          },
          separatorBuilder: (context, index) => Divider(height: .0),
        ),
      ),
    );
  }
}

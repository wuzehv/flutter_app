import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/models/codeup.dart';

class CodeUpMr extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpMr({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpMrState();
}

class _CodeUpMrState extends State<CodeUpMr> with SingleTickerProviderStateMixin {
  final Map<String, List<Map<String, dynamic>>> _itemsMap = {};

  late TabController _tabController;
  final List<String> _statuses = [mrStatusOpened, mrStatusMerged, mrStatusClosed, 'null'];
  final List<String> _tabTitles = ['已开启', '已合并', '已关闭', '全部'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);

    // 监听 tab 切换
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // 避免快速切换时重复触发
      final status = _statuses[_tabController.index];
      _loadData(status);
    });

    // 首次加载，直接调用_loadData会导致build之前调用了setState，包一下
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(_statuses[0]);
    });
  }

  Future<void> _loadData(String status) async {
    final pageItems = await widget.codeup.getProjectMrList(context, widget.codeup.curProjectId, status);
    setState(() {
      _itemsMap[status] = pageItems;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.codeup.curProjectName),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          final items = _itemsMap[status] ?? [];
          return RefreshIndicator(
            onRefresh: () async => _loadData(status),
            child: items.isNotEmpty
                ? ListView.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          Icons.mediation_rounded,
                          color: items[index]['state'] == 'CLOSED'
                              ? Colors.red
                              : items[index]['state'] == 'MERGED'
                              ? Colors.grey
                              : Colors.green,
                        ),
                        title: Text(items[index]['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${items[index]['source']} -> ${items[index]['target']}'),
                            Text('${items[index]['author']} 创建于 ${items[index]['created']}'),
                            if (!['CLOSED', 'MERGED', 'TO_BE_MERGED'].contains(items[index]['state']))
                              Text(
                                items[index]['state'],
                                style: TextStyle(backgroundColor: Colors.red, color: Colors.white),
                              ),
                            Row(
                              children: [
                                if (!['CLOSED', 'MERGED'].contains(items[index]['state']))
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    label: Icon(Icons.close, color: Colors.white),
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (content) {
                                          return AlertDialog(
                                            content: Text("确认关闭合并请求吗?"),
                                            actions: <Widget>[
                                              TextButton(child: Text("取消"), onPressed: () => context.pop()),
                                              TextButton(
                                                child: Text("确认"),
                                                onPressed: () {
                                                  widget.codeup.closeMr(context, widget.codeup.curProjectId, items[index]['id']);
                                                  context.pop();
                                                  _loadData(status);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                SizedBox(width: 15),
                                if (items[index]['state'] == 'TO_BE_MERGED')
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    label: Icon(Icons.check, color: Colors.white),
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (content) {
                                          return AlertDialog(
                                            content: Text("确认完成合并请求吗?"),
                                            actions: <Widget>[
                                              TextButton(child: Text("取消"), onPressed: () => context.pop()),
                                              TextButton(
                                                child: Text("确认"),
                                                onPressed: () {
                                                  widget.codeup.okMr(context, widget.codeup.curProjectId, items[index]['id']);
                                                  context.pop();
                                                  _loadData(status);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(height: .0),
                  )
                : Center(child: Text('暂无数据')),
          );
        }).toList(),
      ),
    );
  }
}

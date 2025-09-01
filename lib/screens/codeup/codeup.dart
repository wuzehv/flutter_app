import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/home_bottom.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/screens/codeup/codeup_item.dart';
import 'package:jenkins_app/screens/left_drawer.dart';
import 'package:provider/provider.dart';

class CodeUp extends StatefulWidget {
  const CodeUp({super.key});

  @override
  State<StatefulWidget> createState() => _CodeUpState();
}

class _CodeUpState extends State<CodeUp> {
  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    context.read<CodeUpProvider>().list();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CodeUp列表"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.dashboard, color: Colors.blue),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: LeftDrawer(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        onPressed: () => context.push('/codeup_config'),
        tooltip: '添加配置',
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: HomeBottom(pageIdx: 1),
      body: Consumer<CodeUpProvider>(
        builder: (context, provider, child) {
          return provider.items.isEmpty
              ? Center(child: Text('请添加配置'))
              : SafeArea(
                  child: SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) => CodeUpItem(codeup: provider.items[index]),
                    ),
                  ),
                );
        },
      ),
    );
  }
}

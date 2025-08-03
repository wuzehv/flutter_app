import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/pages/jenkins_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final list = await JenkinsStore.list();
    setState(() {
      items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Jenkins App"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.dashboard, color: Colors.blue),
              onPressed: () {},
            );
          },
        ),
      ),
      body: items.isEmpty
          ? Center(child: Text('请添加配置'))
          : SafeArea(
              child: SlidableAutoCloseBehavior(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      JenkinsItem(jenkins: items[index]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "jenkins_config"),
        tooltip: '添加配置',
        child: const Icon(Icons.add),
      ),
    );
  }
}

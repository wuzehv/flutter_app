import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/pages/jenkins_item.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    print(packageInfo.version);
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
      // bottomNavigationBar: BottomAppBar(
      //   height: 50,
      //   color: Colors.white,
      //   shape: CircularNotchedRectangle(), // 底部导航栏打一个圆形的洞
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}, padding: EdgeInsets.zero),
      //       SizedBox(),
      //       IconButton(icon: Icon(Icons.touch_app_rounded), onPressed: () {}, padding: EdgeInsets.zero),
      //     ],
      //   ),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        onPressed: () => Navigator.pushNamed(context, "jenkins_config"),
        tooltip: '添加配置',
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? Center(child: Text('请添加配置'))
          : SafeArea(
              child: SlidableAutoCloseBehavior(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => JenkinsItem(jenkins: items[index]),
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeBottom extends StatefulWidget {
  final int pageIdx;

  const HomeBottom({super.key, required this.pageIdx});

  @override
  State<StatefulWidget> createState() => _HomeBottomState();
}

class _HomeBottomState extends State<HomeBottom> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // 底部导航
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.build), label: '发布'),
        BottomNavigationBarItem(icon: Icon(Icons.fork_right), label: '代码管理'),
      ],
      currentIndex: widget.pageIdx,
      fixedColor: Colors.blue,
      onTap: (int index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/codeup');
            break;
        }
      },
    );
  }
}

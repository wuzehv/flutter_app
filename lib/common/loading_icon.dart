import 'package:flutter/material.dart';

class LoadingIcon extends StatefulWidget {
  const LoadingIcon({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingIconState();
}

class _LoadingIconState extends State<LoadingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, color: Colors.blue),
    );
  }
}

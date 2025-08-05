import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jenkins_app/common/shared.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/pages/jenkins.dart';
import 'package:dio/dio.dart';
import 'package:oktoast/oktoast.dart';

class JenkinsItem extends StatefulWidget {
  final Jenkins jenkins;

  const JenkinsItem({super.key, required this.jenkins});

  @override
  State<StatefulWidget> createState() => _JenkinsItemState();
}

class _JenkinsItemState extends State<JenkinsItem> {
  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: const ValueKey(0),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => Navigator.of(context).pushNamed("jenkins_config", arguments: widget.jenkins),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '修改',
          ),
          SlidableAction(
            onPressed: (_) {
              JenkinsStore.remove(widget.jenkins.id!);
              Navigator.pushReplacementNamed(context, '/');
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: ListTile(
        title: Text(widget.jenkins.remark, style: TextStyle(fontSize: 18.0)),
        subtitle: Text(
          widget.jenkins.url,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey, fontSize: 13.5),
        ),
        onTap: () async {
          try {
            await widget.jenkins.getJobList();
            Navigator.pushNamed(context, 'jenkins_job', arguments: widget.jenkins);
          } catch (e) {
            showError('请求失败，请检查网络和配置信息');
          }
        },
      ),
    );
  }
}

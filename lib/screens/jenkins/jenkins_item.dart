import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

class JenkinsItem extends StatefulWidget {
  final JenkinsModel jenkins;

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
            onPressed: (_) => context.push('/jenkins_config', extra: widget.jenkins),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '修改',
          ),
          SlidableAction(
            onPressed: (_) async {
              await context.read<JenkinsProvider>().remove(widget.jenkins.id!);
              context.go('/');
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
            await context.read<JenkinsJobProvider>().setJenkins(widget.jenkins).fetchJobs();
            context.push('/job', extra: widget.jenkins.remark);
          } catch (e) {
            showError('请求失败，请检查网络和配置信息');
          }
        },
      ),
    );
  }
}

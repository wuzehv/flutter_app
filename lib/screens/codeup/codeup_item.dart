import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/util.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

import '../../common/loading.dart';

class CodeUpItem extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpItem({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpItemState();
}

class _CodeUpItemState extends State<CodeUpItem> {
  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: const ValueKey(0),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => context.push('/codeup_config', extra: widget.codeup),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '修改',
          ),
          SlidableAction(
            onPressed: (_) {
              context.read<CodeUpProvider>().remove(widget.codeup.orgId);
              context.go('/codeup');
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: ListTile(
        title: Text(widget.codeup.remark, style: TextStyle(fontSize: 18.0)),
        subtitle: Text(
          widget.codeup.orgId,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey, fontSize: 13.5),
        ),
        onTap: () async {
          final loader = context.read<LoadingProvider>();
          loader.show();
          try {
            await widget.codeup.getProjectList(context, 1);
            context.push('/codeup/project', extra: widget.codeup);
          } catch (e) {}
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

class CodeUpProject extends StatefulWidget {
  final CodeUpModel codeup;

  const CodeUpProject({super.key, required this.codeup});

  @override
  State<StatefulWidget> createState() => _CodeUpProjectState();
}

class _CodeUpProjectState extends State<CodeUpProject> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.codeup.remark)),
      body: ListView.separated(
        itemCount: widget.codeup.projectList.length,
        itemBuilder: (context, index) {
          final project = widget.codeup.projectList[index];

          return ExpansionTile(
            title: Text(project['name']),
            subtitle: Text((project['desc'] == null ? '' : project['desc'] + ' · ') + "更新于 ${project['update']}"),
            // onExpansionChanged: (_) => provider.toggleExpanded(project.name),
            // children: provider.getOperation(context, project.name),
          );
        },
        separatorBuilder: (context, index) => Divider(height: .0),
      ),
    );
  }
}

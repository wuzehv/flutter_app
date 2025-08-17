import 'package:flutter/material.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:provider/provider.dart';

class JenkinsProject extends StatefulWidget {
  final String name;

  const JenkinsProject({super.key, required this.name});

  @override
  State<StatefulWidget> createState() => _JenkinsProjectState();
}

class _JenkinsProjectState extends State<JenkinsProject> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: ListView.builder(
        itemCount: context.read<JenkinsProjectProvider>().projects.length,
        itemBuilder: (context, index) {
          final project = context.read<JenkinsProjectProvider>().projects[index];

          return Selector<JenkinsProjectProvider, bool>(
            selector: (_, provider) => provider.isExpanded(project.name),
            builder: (context, expanded, child) {
              final provider = context.read<JenkinsProjectProvider>();

              return ExpansionTile(
                title: Text(project.name),
                initiallyExpanded: expanded,
                onExpansionChanged: (_) => provider.toggleExpanded(project.name),
                children: provider.getOperation(context, project.name),
              );
            },
          );
        },
      ),
    );
  }
}

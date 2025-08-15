import 'package:flutter/cupertino.dart';
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
      // body: Consumer<JenkinsProjectProvider>(
      //   builder: (context, provider, child) {
      //     return ListView.builder(
      //       itemCount: provider.projects.length,
      //       itemBuilder: (context, index) {
      //         return ExpansionTile(
      //           title: Text(provider.projects[index].name),
      //           onExpansionChanged: (bool expanded) {
      //             if (expanded) {
      //               context.read<JenkinsProjectProvider>().getOperation(provider.projects[index].name);
      //             }
      //           },
      //           children: provider.getOperation(provider.projects[index].name),
      //         );
      //       },
      //     );
      //   },
      // ),
      // body: ListView(
      // children: (widget.jenkins.projects ?? []).map<Widget>((project) {
      //   return ExpansionTile(
      //     title: Text(project),
      //     children: [
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.end,
      //         children: [
      //           Column(
      //             children: [
      //               Row(
      //                 children: [
      //                   ElevatedButton(
      //                     onPressed: () => widget.jenkins.toProjectPage(context, project, 'tra'),
      //                     child: Text("tra"),
      //                   ),
      //                   SizedBox(width: 7),
      //                   ElevatedButton(
      //                     onPressed: () => widget.jenkins.toProjectPage(context, project, 'pro'),
      //                     child: Text("pro"),
      //                   ),
      //                   SizedBox(width: 7),
      //                   ElevatedButton(
      //                     onPressed: () => widget.jenkins.toProjectPage(context, project, 'customize'),
      //                     child: Text("自定义"),
      //                   ),
      //                   SizedBox(width: 7),
      //                   ElevatedButton.icon(
      //                     onPressed: () async {
      //                       if (!widget.jenkins.checkProjectImpl(project)) {
      //                         showError('当前项目未实现');
      //                         return;
      //                       }
      //                       try {
      //                         await widget.jenkins.getProjectBuildLog(project);
      //                         context.push('/job/project/log', extra: widget.jenkins);
      //                       } catch (e) {
      //                         print(e);
      //                         showError('请求失败，请检查网络和配置信息');
      //                       }
      //                     },
      //                     icon: Icon(Icons.playlist_add_check_outlined),
      //                     label: Text("审核"),
      //                   ),
      //                 ],
      //               ),
      //             ],
      //           ),
      //         ],
      //       ),
      //     ],
      //   );
      // }).toList(),
      // ),
    );
  }
}

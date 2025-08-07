import 'package:flutter/material.dart';
import 'package:jenkins_app/pages/home_page.dart';
import 'package:jenkins_app/pages/jenkins.dart';
import 'package:jenkins_app/pages/jenkins_build_wms_be.dart';
import 'package:jenkins_app/pages/jenkins_config.dart';
import 'package:jenkins_app/pages/jenkins_job.dart';
import 'package:jenkins_app/pages/jenkins_project.dart';
import 'package:jenkins_app/pages/jenkins_project_build_log.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/cupertino.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Flutter Demo',
        initialRoute: "/",
        theme: ThemeData.light(),
        routes: {
          '/': (context) => const HomePage(),
          'jenkins_config': (context) => JenkinsConfig(),
          'jenkins_job': (context) => JenkinsJob(jenkins: ModalRoute.of(context)!.settings.arguments as Jenkins),
          'jenkins_project': (context) => JenkinsProject(jenkins: ModalRoute.of(context)!.settings.arguments as Jenkins),
          'jenkins_project_build_log': (context) =>
              JenkinsProjectBuildLog(jenkins: ModalRoute.of(context)!.settings.arguments as Jenkins),
          'jenkins_build_wms_be': (context) => JenkinsBuildWmsBe(jenkins: ModalRoute.of(context)!.settings.arguments as Jenkins),
        },
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

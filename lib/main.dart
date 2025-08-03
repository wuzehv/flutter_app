import 'package:flutter/material.dart';
import 'package:jenkins_app/pages/home_page.dart';
import 'package:jenkins_app/pages/jenkins_config.dart';
import 'package:oktoast/oktoast.dart';

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
        },
      ),
    );
  }
}

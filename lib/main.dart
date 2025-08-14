import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/screens/home_page.dart';
import 'package:jenkins_app/screens/jenkins.dart';
import 'package:jenkins_app/screens/jenkins_build_wms_be.dart';
import 'package:jenkins_app/screens/jenkins_config.dart';
import 'package:jenkins_app/screens/jenkins_job.dart';
import 'package:jenkins_app/screens/jenkins_project.dart';
import 'package:jenkins_app/screens/jenkins_project_build_log.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/cupertino.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp.router(routerConfig: _router, theme: ThemeData.light()),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const HomePage(),
      routes: <RouteBase>[
        GoRoute(
          path: 'job',
          builder: (BuildContext context, GoRouterState state) {
            final jenkins = state.extra as Jenkins;
            return JenkinsJob(jenkins: jenkins);
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'project',
              builder: (BuildContext context, GoRouterState state) {
                final jenkins = state.extra as Jenkins;
                return JenkinsProject(jenkins: jenkins);
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'log',
                  builder: (BuildContext context, GoRouterState state) {
                    final jenkins = state.extra as Jenkins;
                    return JenkinsProjectBuildLog(jenkins: jenkins);
                  },
                ),
                GoRoute(
                  path: 'wms_be',
                  builder: (BuildContext context, GoRouterState state) {
                    final jenkins = state.extra as Jenkins;
                    return JenkinsBuildWmsBe(jenkins: jenkins);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/config',
      builder: (BuildContext context, GoRouterState state) {
        return JenkinsConfig(jenkins: state.extra as Jenkins?);
      },
    ),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

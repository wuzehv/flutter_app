import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/loading.dart';
import 'package:jenkins_app/common/theme.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/codeup/codeup.dart';
import 'package:jenkins_app/screens/codeup/codeup_config.dart';
import 'package:jenkins_app/screens/codeup/codeup_mr.dart';
import 'package:jenkins_app/screens/codeup/codeup_project.dart';
import 'package:jenkins_app/screens/home.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_config.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_job.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_log.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp.router(routerConfig: _router, theme: appTheme),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return Stack(
          children: [
            child,
            Selector<LoadingProvider, bool>(
              selector: (_, p) => p.loading,
              builder: (_, loading, __) {
                if (!loading) return SizedBox.shrink();
                return Center(child: CircularProgressIndicator(color: Colors.blue));
              },
            ),
          ],
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => const Home(),
          routes: <RouteBase>[
            GoRoute(
              path: 'job',
              builder: (BuildContext context, GoRouterState state) => JenkinsJob(name: state.extra.toString()),
              routes: <RouteBase>[
                GoRoute(
                  path: 'log',
                  builder: (BuildContext context, GoRouterState state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return JenkinsLog(jenkins: extra['obj'] as JenkinsModel, name: extra['name'], searchOptions: extra['jobs'],);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'codeup',
              builder: (BuildContext context, GoRouterState state) => CodeUp(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'project',
                  builder: (BuildContext context, GoRouterState state) => CodeUpProject(codeup: state.extra as CodeUpModel),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'mr',
                      builder: (BuildContext context, GoRouterState state) => CodeUpMr(codeup: state.extra as CodeUpModel),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/jenkins_config',
          builder: (BuildContext context, GoRouterState state) => JenkinsConfig(jenkins: state.extra as JenkinsModel?),
        ),
        GoRoute(
          path: '/codeup_config',
          builder: (BuildContext context, GoRouterState state) => CodeUpConfig(codeUp: state.extra as CodeUpModel?),
        ),
      ],
    ),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => JenkinsProvider()),
        ChangeNotifierProvider(create: (context) => JenkinsJobProvider()),
        ChangeNotifierProvider(create: (context) => JenkinsProjectProvider()),
        ChangeNotifierProvider(create: (context) => LoadingProvider()),

        ChangeNotifierProvider(create: (context) => CodeUpProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

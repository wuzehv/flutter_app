import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/theme.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/models/jenkins_shipla.dart';
import 'package:jenkins_app/models/jenkins_wms_be.dart';
import 'package:jenkins_app/models/jenkins_wms_fe.dart';
import 'package:jenkins_app/models/loading.dart';
import 'package:jenkins_app/project_screens/shipla_build.dart';
import 'package:jenkins_app/project_screens/shipla_log.dart';
import 'package:jenkins_app/project_screens/wms_be_build.dart';
import 'package:jenkins_app/project_screens/wms_be_log.dart';
import 'package:jenkins_app/project_screens/wms_fe_build.dart';
import 'package:jenkins_app/project_screens/wms_fe_log.dart';
import 'package:jenkins_app/screens/home.dart';
import 'package:jenkins_app/screens/jenkins_config.dart';
import 'package:jenkins_app/screens/jenkins_job.dart';
import 'package:jenkins_app/screens/jenkins_project.dart';
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
                return Container(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                );
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
                  path: 'project',
                  builder: (BuildContext context, GoRouterState state) => JenkinsProject(name: state.extra.toString()),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'wms_be_build',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return WmsBeBuild(
                          jenkins: extra['obj'] as JenkinsWmsBe,
                          env: extra['env'],
                          envList: extra['env_list'],
                          approver: extra['approver'],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'wms_be_log',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return WmsBeLog(jenkins: extra['obj'] as JenkinsWmsBe, logList: extra['log_list']);
                      },
                    ),

                    GoRoute(
                      path: 'wms_fe_build',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return WmsFeBuild(
                          jenkins: extra['obj'] as JenkinsWmsFe,
                          env: extra['env'],
                          envList: extra['env_list'],
                          approver: extra['approver'],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'wms_fe_log',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return WmsFeLog(jenkins: extra['obj'] as JenkinsWmsFe, logList: extra['log_list']);
                      },
                    ),

                    GoRoute(
                      path: 'shipla_build',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return ShiplaBuild(
                          jenkins: extra['obj'] as JenkinsShipla,
                          params: extra['params'],
                          approver: extra['approver'],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'shipla_log',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return ShiplaLog(jenkins: extra['obj'] as JenkinsShipla, logList: extra['log_list']);
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
          builder: (BuildContext context, GoRouterState state) => JenkinsConfig(jenkins: state.extra as JenkinsModel?),
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
      ],
      child: const MyApp(),
    ),
  );
}

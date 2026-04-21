import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:jenkins_app/common/loading.dart';
import 'package:jenkins_app/common/theme.dart';
// import 'package:jenkins_app/common/biometric_provider.dart';
// import 'package:jenkins_app/common/biometric_overlay.dart';
import 'package:jenkins_app/models/codeup.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/screens/codeup/codeup.dart';
import 'package:jenkins_app/screens/codeup/codeup_branches.dart';
import 'package:jenkins_app/screens/codeup/codeup_config.dart';
import 'package:jenkins_app/screens/codeup/codeup_mr.dart';
import 'package:jenkins_app/screens/codeup/codeup_mr_diff.dart';
import 'package:jenkins_app/screens/codeup/codeup_mr_file_diff.dart';
import 'package:jenkins_app/screens/codeup/codeup_project.dart';
import 'package:jenkins_app/screens/dashboard.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_config.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_job.dart';
import 'package:jenkins_app/screens/jenkins/jenkins_log.dart';
import 'package:jenkins_app/screens/jenkins/shipla_publish_page.dart';
import 'package:jenkins_app/screens/jenkins/wms_publish_page.dart';
import 'package:jenkins_app/screens/jenkins/neo_publish_page.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp.router(
        routerConfig: _router,
        theme: appTheme,
      ),
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
          builder: (BuildContext context, GoRouterState state) => const Dashboard(),
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
                // 通用发布页面路由，根据项目名动态选择页面
                GoRoute(
                  path: 'build_:projectName',
                  builder: (BuildContext context, GoRouterState state) {
                    final projectName = state.pathParameters['projectName']!;
                    final extra = state.extra as Map<String, dynamic>;
                    final jenkins = extra['obj'] as JenkinsModel;
                    final initialBranch = extra['targetBranch'] as String?;
                    
                    // 根据项目名决定使用哪个发布页面
                    if (projectName.toLowerCase().contains('shipla')) {
                      return ShiplaPublishPage(
                        projectName: projectName,
                        jenkins: jenkins,
                        initialBranch: initialBranch,
                      );
                    } else if (projectName.toLowerCase().contains('neo')) {
                      return NeoPublishPage(
                        projectName: projectName,
                        jenkins: jenkins,
                        initialBranch: initialBranch,
                      );
                    } else {
                      // 默认使用 WMS 发布页面
                      return WmsPublishPage(
                        projectName: projectName,
                        jenkins: jenkins,
                        initialBranch: initialBranch,
                      );
                    }
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
                    GoRoute(
                      path: 'mr_diff',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return CodeUpMrDiff(
                          codeup: extra['codeup'] as CodeUpModel,
                          projectId: extra['projectId'] as int,
                          mrId: extra['mrId'] as int,
                          mrTitle: extra['mrTitle'] as String,
                          sourcePatchSetBizId: extra['sourcePatchSetBizId'] as String?,
                          targetPatchSetBizId: extra['targetPatchSetBizId'] as String?,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'mr_file_diff',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return CodeUpMrFileDiff(
                          codeup: extra['codeup'] as CodeUpModel,
                          projectId: extra['projectId'] as int,
                          mrId: extra['mrId'] as int,
                          mrTitle: extra['mrTitle'] as String,
                          filePath: extra['filePath'] as String,
                          fromCommitId: extra['fromCommitId'] as String?,
                          toCommitId: extra['toCommitId'] as String?,
                          isNew: extra['isNew'] as bool? ?? false,
                          isDeleted: extra['isDeleted'] as bool? ?? false,
                          isBinary: extra['isBinary'] as bool? ?? false,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'branches',
                      builder: (BuildContext context, GoRouterState state) => CodeUpBranches(codeup: state.extra as CodeUpModel),
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
  
  /* // 初始化生物识别提供者
  final biometricProvider = BiometricProvider();
  biometricProvider.init(); */
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => JenkinsProvider()),
        ChangeNotifierProvider(create: (context) => JenkinsJobProvider()),
        ChangeNotifierProvider(create: (context) => JenkinsProjectProvider()),
        ChangeNotifierProvider(create: (context) => LoadingProvider()),
        ChangeNotifierProvider(create: (context) => CodeUpProvider()),
        // ChangeNotifierProvider.value(value: biometricProvider),
      ],
      child: MyApp(),
    ),
  );
}
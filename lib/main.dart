import 'package:buff_helper/pag_helper/comm/comm_app.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_theme_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/theme/theme_data_minimal.dart';
import 'package:buff_helper/pag_helper/theme/theme_data_vivid.dart';
import 'package:buff_helper/pag_helper/theme/theme_setting.dart';
import 'package:buff_helper/pag_helper/wgt/user/pg_my_profile.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pag_ems_tp/app_config.dart';
import 'package:pag_ems_tp/app_context/app_context_board.dart';
import 'package:pag_ems_tp/pg_project_public_front.dart';
import 'package:buff_helper/pag_helper/page/pg_tech_issue.dart';
import 'package:pag_ems_tp/user_service/pg_login.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  // String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  // String buildNumber = packageInfo.buildNumber;

  String latestVersion = await getVersion2(appName, pagAppConfig);
  String oreVersion = await getOreVersion2(null, pagAppConfig);

  Map<String, dynamic>? portalScopeProfile = getPortalProjectScopeProfile(
    activePortalPagProjectScopeList[0],
  );
  if (portalScopeProfile == null) {
    if (kDebugMode) {
      print('Project profile not found');
    }
    throw Exception('Project profile not found');
  }

  Map<String, dynamic> firebaseOptions =
      portalScopeProfile['firebase_options'] ?? {};
  if (firebaseOptions.isEmpty) {
    throw Exception('Firebase options not found');
  } else {
    try {
      final FirebaseOptions options = FirebaseOptions(
        apiKey: firebaseOptions['apiKey'],
        authDomain: firebaseOptions['authDomain'],
        projectId: firebaseOptions['projectId'],
        storageBucket: firebaseOptions['storageBucket'],
        messagingSenderId: firebaseOptions['messagingSenderId'],
        appId: firebaseOptions['appId'],
      );
      await Firebase.initializeApp(options: options);
    } catch (e) {
      if (kDebugMode) {
        print('Firebase.initializeApp error: $e');
      }
    }
  }

  await iniSharedPref();

  runApp(
    // const MainApp(),
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PagAppProvider()),
        ChangeNotifierProvider(
          create: (context) => PagThemeProvider(isDark: true),
        ),
        ChangeNotifierProvider(
          create: (context) => PagUserProvider(
            firebaseUser: FirebaseAuth.instance.currentUser,
          ),
        ),
      ],
      child: MainApp(
        appName,
        version,
        latestVersion,
        oreVersion,
        thmPagNeoLight,
        thmPagNeo,
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp(
    this.appName,
    this.version,
    this.latestVer,
    this.oreVersion,
    this.themeData,
    this.themeDataDark, {
    super.key,
  });

  final String appName;
  final String version;
  final String latestVer;
  final String oreVersion;
  final ThemeData themeData;
  final ThemeData themeDataDark;

  final appTitle = 'Energy@Grid EMS Tenant Portal';

  @override
  Widget build(BuildContext context) {
    // return const MaterialApp(
    //   home: Scaffold(body: Center(child: Text('Hello World!'))),
    // );
    PagAppProvider appModel = Provider.of<PagAppProvider>(
      context,
      listen: false,
    );
    appModel.appName = appName;
    appModel.appVer = version;
    appModel.latestVer = latestVer;
    appModel.oreVer = oreVersion;

    ThemeData themeData = thmPagNeoLight;
    ThemeData themeDataDark = thmPagNeo;

    String themeKey = Provider.of<PagThemeProvider>(context).getThemeKey();
    switch (themeKey) {
      case 'vivid':
        themeData = pagThemeVividLight;
        themeDataDark = pagThemeVividDark;
        break;
      case 'minimal':
        themeData = pagThemeMinimalLight;
        themeDataDark = pagThemeMinimalDark;
        break;
      default:
        // themeData = thmPagNeoLight;
        // themeDataDark = thmPagNeo;
        themeData = pagThemeMinimalLight;
        themeDataDark = pagThemeMinimalDark;
        break;
    }

    return Consumer<PagThemeProvider>(
      builder: (context, PagThemeProvider themeNotifier, child) {
        return MaterialApp.router(
          routerConfig: _router,
          title: appTitle,
          theme: themeData,
          darkTheme: themeDataDark,
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  // the above is embedded case for route '/'
  // if so '/' is called every time for any route
  // before the actual route is called
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.consoleHomeDashboard;

        return const AppContextBoard(
            pageRoute: PagPageRoute.consoleHomeDashboard);
      },
    ),
    // GoRoute(
    //     path: getRoute(PagPageRoute.splash),
    //     builder: (context, state) {
    //       Provider.of<PagAppProvider>(context, listen: false).prCur =
    //           PagPageRoute.splash;
    //       return const PgSplash();
    //     }),
    GoRoute(
      path: getRoute(PagPageRoute.projectPublicFront),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.projectPublicFront;
        return const PgProjectPublicFront();
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.techIssue),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.techIssue;
        return const PgTechIssue();
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.login),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.login;
        return const PgLogin();
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.myProfile),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.myProfile;
        return PagPgMyProfile(appConfig: pagAppConfig);
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.consoleHomeDashboard),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.consoleHomeDashboard;
        return const AppContextBoard(
            pageRoute: PagPageRoute.consoleHomeDashboard);
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.meterManager),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.meterManager;
        return const AppContextBoard(pageRoute: PagPageRoute.meterManager);
      },
    ),
    GoRoute(
      path: getRoute(PagPageRoute.billingManager),
      builder: (context, state) {
        Provider.of<PagAppProvider>(context, listen: false).prCur =
            PagPageRoute.billingManager;
        return const AppContextBoard(pageRoute: PagPageRoute.billingManager);
      },
    ),
  ],
  //   ),
  // ],
);

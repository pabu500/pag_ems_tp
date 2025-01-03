import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/user/pg_splash.dart';
import 'package:buff_helper/pag_helper/wgt/user/post_login.dart';
import 'package:buff_helper/pag_helper/wgt/user/wgt_login.dart';
import 'package:buff_helper/xt_ui/painter/pag_bg_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_config.dart';
import 'package:provider/provider.dart';

class PgLogin extends StatefulWidget {
  const PgLogin({super.key});

  @override
  State<PgLogin> createState() => _PgLoginState();
}

class _PgLoginState extends State<PgLogin> {
  MdlPagUser? _loggedInUser;
  bool _postLoginDone = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('PgLogin.initState()');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('PgLogin.build()');
    }

    if (_postLoginDone) {
      routeGuard(context, _loggedInUser, goHome: true);
    }

    bool isLoggedIn = _loggedInUser != null && !_loggedInUser?.isEmpty;
    return !isLoggedIn
        ? Scaffold(
            body: CustomPaint(
              painter: NeoDotPatternPainter(
                color: Colors.grey.shade600.withAlpha(80),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WgtLogin(
                      appConfig: pagAppConfig,
                      onLoggedIn: (MdlPagUser user) {
                        setState(() {
                          _loggedInUser = user;
                        });
                      },
                      // onPostLogin: _onPostLogin,
                      // postLoginThen: (MdlPagUser user) {
                      //   Provider.of<PagUserProvider>(context, listen: false)
                      //       .setCurrentUser(user);
                      //   // Provider.of<PagAppProvider>(context, listen: false)
                      //   //     .iniPageRoute(PagPageRoute.consoleHomeDashboard);

                      //   context.go(getRoute(PagPageRoute.splash));
                      // },
                    ),
                  ],
                ),
              ),
            ),
          )
        : PgSplash(
            key: UniqueKey(),
            appConfig: pagAppConfig,
            loggedInUser: _loggedInUser,
            doPostLogin: true,
            doPostLoginFunction: doPostLogin,
            showProgress: true,
            // appCtxBoardContext: context,
            onSplashDone: (user) {
              setState(() {
                _postLoginDone = true;

                _loggedInUser = user;

                Provider.of<PagUserProvider>(
                  context,
                  listen: false,
                ).setCurrentUser(user);
              });
              // GoRouter.of(context).go(
              //     getRoute(PagPageRoute.projectPublicFront));
            },
          );
  }
}

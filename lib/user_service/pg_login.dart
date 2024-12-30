import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/user/wgt_login.dart';
import 'package:buff_helper/xt_ui/painter/pag_bg_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pag_ems_tp/app_config.dart';
import 'package:provider/provider.dart';

class PgLogin extends StatefulWidget {
  const PgLogin({super.key});

  @override
  State<PgLogin> createState() => _PgLoginState();
}

class _PgLoginState extends State<PgLogin> {
  Future<dynamic> _onPostLogin(MdlPagUser loggedInUser) async {
    try {} catch (e) {
      if (kDebugMode) {
        print('_onPostLogin: $e');
      }
    } finally {}
  }

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
    return Scaffold(
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
                onPostLogin: _onPostLogin,
                postLoginThen: (MdlPagUser user) {
                  Provider.of<PagUserProvider>(context, listen: false)
                      .iniUser(user);
                  Provider.of<PagAppProvider>(context, listen: false)
                      .iniPageRoute(PagPageRoute.consoleHomeDashboard);

                  context.push(getRoute(PagPageRoute.splash));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> doPostLogin(BuildContext context, MdlPagUser loggedInUser,
    {bool loadVendorCredential = true, PagPageRoute? prCur}) async {
  if (kDebugMode) {
    print('doPostLogin');
  }
  Provider.of<PagUserProvider>(context, listen: false).iniUser(loggedInUser);
  Provider.of<PagAppProvider>(context, listen: false)
      .iniPageRoute(prCur ?? PagPageRoute.consoleHomeDashboard);

  // if (loadVendorCredential) {
  //   await doLoadVendorCredential(loggedInUser, pagAppConfig);
  // }
}

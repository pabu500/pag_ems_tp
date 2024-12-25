import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:pag_ems_tp/app_config.dart';

Future<MdlPagUser> doLoginPag(Map<String, String> formData) async {
  String url = PagUrlController(
    null,
    pagAppConfig,
  ).getUrl(PagSvcType.usersvc2, PagUrlBase.eptUsersvcLogin);
  final response = await http.post(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      PagUserKey.username.name: formData[PagUserKey.username.name] ?? '',
      PagUserKey.password.name: formData[PagUserKey.password.name] ?? '',
      // PagUserKey.email.name: formData[PagUserKey.email]!,
      // PagUserKey.authProvider.name: formData[PagUserKey.authProvider] ?? '',
      // PagUserKey.destPortal.name: 'pag_console',
      'portal_type': formData['portal_type'] ?? '',
    }),
  );

  if (response.statusCode == 200) {
    if (kDebugMode) {
      print('usersvc comm: getting token from response body');
    }
    String token = jsonDecode(response.body)['token'];

    if (kDebugMode) {
      print('usersvc comm: writing token to secure storage');
    }
    try {
      await storage.write(key: 'pag_user_token', value: token);
    } catch (err) {
      if (kDebugMode) {
        print('usersvc comm: error writing token to secure storage: $err');
      }
    }
    if (kDebugMode) {
      print('usersvc comm: getting user from token');
    }

    MdlPagUser user = MdlPagUser.fromJson2(jsonDecode(response.body));

    if (user.userScope == null) {
      throw Exception('failed to get user scope');
    }

    if (!user.hasScopeForPagProject(activePortalPagProjectScopeList)) {
      throw Exception('no access to this project portal');
    }

    dynamic scopePref = readFromSharedPref('scope_pref');
    if (kDebugMode) {
      print('scopePref: $scopePref');
    }
    Map<String, dynamic> scopePrefMap = json.decode(scopePref ?? '{}');
    String selectedProjectName = scopePrefMap['selected_project_name'] ?? '';
    String selectedSiteGroupName =
        scopePrefMap['selected_site_group_name'] ?? '';
    String selectedSiteName = scopePrefMap['selected_site_name'] ?? '';
    String selectedBuildingName = scopePrefMap['selected_building_name'] ?? '';
    String selectedLocationGroupName =
        scopePrefMap['selected_location_group_name'] ?? '';

    user.updateSelectedScopeByName(
      selectedProjectName,
      selectedSiteGroupName,
      selectedSiteName,
      selectedBuildingName,
      selectedLocationGroupName,
    );

    return user;
  } else {
    if (kDebugMode) {
      print('usersvc comm: error: ${response.body}');
    }
    throw Exception(/*jsonDecode*/ (response.body) /*['err']*/);
  }
}

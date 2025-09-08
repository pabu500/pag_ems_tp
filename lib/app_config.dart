import 'package:buff_helper/pag_helper/def_helper/def_app.dart';
import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

const String productName = 'Energy@Grid Tenant Portal';
const String productOrgName = 'Power Automation Pte Ltd';
const String copyRightYear = '© 2023-2025';

const bool loadDashboard = true;

// this is the list of active portal project scope
// that the deployed portal will support
const List<PagPortalProjectScope> activePortalPagProjectScopeList = [
  PagPortalProjectScope.GI_DE,
  // PagPortalProjectScope.PA_EMS,
  PagPortalProjectScope.ZSP,
  PagPortalProjectScope.MBFC,
  PagPortalProjectScope.SUNSEAP,
  PagPortalProjectScope.CW_P2,
];

MdlPagAppConfig pagAppConfig = MdlPagAppConfig(
  portalType: PagPortalType.pagEmsTp,
  lazyLoadScope: '',
  loadDashboard: loadDashboard,
  userSvcEnv: DeploymentTeir.unset.name,
  oreSvcEnv: DeploymentTeir.unset.name,
  activePortalPagProjectScopeList: activePortalPagProjectScopeList,
);

Future<void> initializeAppConfig() async {
  dev.log('Initializing App Config for ${pagAppConfig.portalType}');
  if (kDebugMode) {
    pagAppConfig = MdlPagAppConfig(
      portalType: PagPortalType.pagEmsTp,
      lazyLoadScope: '',
      loadDashboard: loadDashboard,
      userSvcEnv: DeploymentTeir.dev.name,
      oreSvcEnv: DeploymentTeir.dev.name,
      activePortalPagProjectScopeList: activePortalPagProjectScopeList,
    );
  } else {
    String url = web.window.location.origin;
    final response = await http.post(Uri.parse('$url/app_config'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      // print('App Config Data: ${data['oreSvcTargetTier']} ${data['userSvcTargetTier']}');

      pagAppConfig = MdlPagAppConfig(
        portalType: PagPortalType.pagEmsTp,
        lazyLoadScope: '',
        loadDashboard: loadDashboard,
        userSvcEnv: data['userSvcTargetTier'] ?? DeploymentTeir.unset.name,
        oreSvcEnv: data['oreSvcTargetTier'] ?? DeploymentTeir.unset.name,
        activePortalPagProjectScopeList: activePortalPagProjectScopeList,
      );
    } else {
      print('response.body: ${response.body}');
      throw Exception('Failed to load config');
    }
  }
}

import 'package:buff_helper/pag_helper/def_helper/def_app.dart';
import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';

const String productName = 'Energy@Grid';
const String productOrgName = 'Power Automation Pte Ltd';
const String copyRightYear = '© 2023-2025';

const bool loadDashboard = true;

// use dev oresvc in release mode
// const bool useDevOresvc = true;
// use dev usersvc in release mode
// const bool useDevUsersvc = true;
const DeploymentTeir oreSvcTargetTier = DeploymentTeir.dev;
const DeploymentTeir userSvcTargetTier = DeploymentTeir.dev;

// setting here is used to hard limit the scope of the portal
// when deploying to different environment.
// actual limit within the hard limit will be determined by ACL

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

final MdlPagAppConfig pagAppConfig = MdlPagAppConfig(
  portalType: PagPortalType.pagEmsTp,
  lazyLoadScope: 'site_group',
  loadDashboard: loadDashboard,
  // useDevOresvc: useDevOresvc,
  // useDevUsersvc: useDevUsersvc,
  oreSvcEnv: oreSvcTargetTier.name,
  userSvcEnv: userSvcTargetTier.name,
  activePortalPagProjectScopeList: activePortalPagProjectScopeList,
);

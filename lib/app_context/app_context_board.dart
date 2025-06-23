import 'dart:async';
import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/def/def_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_theme_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/page/pg_tech_issue.dart';
import 'package:buff_helper/pag_helper/theme/theme_setting.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/pag_helper/wgt/app_context_menu.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_selector3.dart';
import 'package:buff_helper/pag_helper/wgt/user/pg_splash.dart';
import 'package:buff_helper/pag_helper/wgt/user/post_login.dart';
import 'package:buff_helper/pag_helper/wgt/user/wgt_user_tenant_selector.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_pag.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_panel_container.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pag_ems_tp/app_context/ems/wgt_app_context_ems.dart';
import 'package:buff_helper/pag_helper/wgt/app/app_context_drawer.dart';
import 'package:pag_ems_tp/pg_project_public_front.dart';
import 'package:buff_helper/pag_helper/wgt/user/user_menu.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';

class AppContextBoard extends StatefulWidget {
  const AppContextBoard({super.key, required this.pageRoute, this.icon});

  final PagPageRoute pageRoute;
  final Widget? icon;

  @override
  State<AppContextBoard> createState() => _AppContextBoardState();
}

class _AppContextBoardState extends State<AppContextBoard>
    with TickerProviderStateMixin {
  bool _initialised = false;

  late MdlPagUser? _loggedInUser;
  bool _isLoggingIn = false;

  late MdlPagAppContext _currentAppContext;

  bool _loadingPagAppContext = false;
  String _loadingMessage = '';

  UniqueKey? _projectLogoKey;
  UniqueKey? _scopeSelectorKey;
  UniqueKey? _contextRefreshKey;
  UniqueKey? _tenantRefreshKey;

  late String _activeScopeStr;

  late String pageTitle;

  bool _showLeftSideSlider = true;
  final double sliderWidth = 250.0;
  bool _leftSliderIsStack = true;

  Timer? _fhRefreshTimer;
  Timer? _refreshStrAnimTimer;
  AnimationController? _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  AnimationController? _rotationAnimationController;
  late Animation<double> _rotationAnimation;

  bool _contextMenuIsStack = true;

  MdlPagTenant? _selectedTenant;
  bool _userError = false;

  UniqueKey? _themeRefreshKey;

  String _currentThemeKey = defaultThemeKey;
  late bool _isDarkMode =
      Provider.of<PagThemeProvider>(context, listen: false).isDark;

  double _boardWidth = 0;

  Future<void> loadAppSetting() async {
    _userError = false;
    _isLoggingIn = true;

    try {
      _loggedInUser = await checkLoginStatus();

      if (_loggedInUser != null) {
        if (mounted) {
          if (kDebugMode) {
            // NOTE: DO NOT USE GoRouterState.of(context).path
            // will cause rebuild issue
            // print('current route:${GoRouterState.of(context).path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _userError = true;
    } finally {
      _isLoggingIn = false;
      if (kDebugMode) {
        print('loadAppSetting done');
      }
      if (_loggedInUser == null) {
        if (mounted) {
          context.go(getRoute(PagPageRoute.projectPublicFront));
        }
      } else {
        if (mounted) {
          // Provider.of<PagUserProvider>(context, listen: false)
          //     .setCurrentUser(_loggedInUser!);
          // context.go(getRoute(PagPageRoute.splash));
        }
      }
    }
  }

  Future<MdlPagUser?> checkLoginStatus() async {
    DateTime now = DateTime.now();

    String? username = await secStorage.read(
      key: PagUserKey.identifier.toString(),
    );
    String? password =
        await secStorage.read(key: PagUserKey.password.toString());

    if (username == null || password == null) {
      return null;
    } else {
      try {
        MdlPagUser user = await doLoginPag(
          pagAppConfig,
          Map.of({
            PagUserKey.username.name: username,
            PagUserKey.password.name: password,
            PagUserKey.email.name: '',
            'portal_type_name': PagPortalType.emsTp.name,
            'portal_type_label': PagPortalType.emsTp.label,
          }),
        );

        if (user.isEmpty) {
          return null;
        }

        DateTime now2 = DateTime.now();
        int diff = now2.difference(now).inMilliseconds;
        int wait = 1000;
        if (diff < wait) {
          int delay = wait - diff;
          await Future.delayed(Duration(milliseconds: delay));
        }

        return user;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return null;
      }
    }
  }

  void _savePref() {
    saveToSharedPref('scope_nav_bar', {
      'isStack': _leftSliderIsStack,
      'showSlider': _showLeftSideSlider,
    });
  }

  void _loadPref() {}

  PagPageRoute? _boardToReset;
  void _resetPanelPositions() {
    if (kDebugMode) {
      print('Reset Panel Positions');
    }
    setState(() {
      _boardToReset = widget.pageRoute;
      _contextRefreshKey = UniqueKey();
    });
  }

  void _ini() {
    if (_initialised) {
      return;
    }

    _loadPref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    _initialised = true;
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _currentAppContext = getPageContext(widget.pageRoute);

    pageTitle = getPageTitle(widget.pageRoute);

    _ini();

    routeGuard(context, _loggedInUser, appContext: _currentAppContext);
  }

  @override
  void dispose() {
    _fhRefreshTimer?.cancel();
    _refreshStrAnimTimer?.cancel();
    _colorAnimationController?.dispose();
    _rotationAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('AppContextBoard.build()');
    }

    bool isLoggedIn = false;
    if (_loggedInUser != null) {
      if (!_loggedInUser!.isEmpty) {
        isLoggedIn = true;
      }
    }

    bool scopeReady = false;
    if (_loggedInUser != null) {
      if (!_loggedInUser!.selectedScope.isEmpty) {
        scopeReady = true;
      }
    }

    if (kDebugMode) {
      print('app_home: loggedIn: $isLoggedIn, scopeReady: $scopeReady');
    }

    _boardWidth = MediaQuery.of(context).size.width -
        ((!_showLeftSideSlider || _leftSliderIsStack)
            ? 30 + 5
            : sliderWidth + 5);

    return !isLoggedIn
        ? FutureBuilder<void>(
            future: loadAppSetting(),
            builder: (context, AsyncSnapshot<void> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  if (kDebugMode) {
                    print(
                        'snapshot.connectionState: ${snapshot.connectionState}');
                  }
                  return PgSplash(
                      appConfig: pagAppConfig,
                      // appCtxBoardContext: context,
                      doPostLoginFunction: doPostLogin,
                      doPostLogin: _loggedInUser != null);
                default:
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      print(snapshot.error);
                    }
                    return PgTechIssue();
                    // homeBoard(
                    //   'Error',
                    //   getErrorTextPrompt(
                    //     context: context,
                    //     errorText: 'Serivce Error',
                    //   ),
                    // );
                  } else {
                    if (_loggedInUser == null || _loggedInUser!.isEmpty) {
                      if (kDebugMode) {
                        print('No user');
                      }
                      return const PgProjectPublicFront();
                    } else {
                      if (kDebugMode) {
                        print('User: ${_loggedInUser!.username}');
                      }

                      return
                          // completedWidget();
                          scopeReady
                              ? completedWidget()
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
              }
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    double ribbonHeight = 50.0;
    if (_loadingPagAppContext) {
      ribbonHeight = 100.0;
    }
    double scopeSliderHeightCap = 650.0;
    String appVer = Provider.of<PagAppProvider>(context).appVer ?? '';
    final bottomText = '$productName $appVer $copyRightYear $productOrgName';

    return Scaffold(
      // key: _scaffold,
      appBar: AppBar(
        centerTitle: true,
        title: buildTitleWidget(),
        leading: Builder(
          builder: (BuildContext context) {
            return InkWell(
              onTap: true
                  // _loadingPagAppContext
                  ? null
                  : () {
                      Scaffold.of(context).openDrawer();
                    },
              child: WgtPaG(
                conextLabel: pageTitle, //_currentAppContext.label,
                size: 35,
                colorA: getColor(context: context, pagWgt: PagWgt.pagCube),
                colorC: _currentAppContext.appContextType ==
                        PagAppContextType.consoleHome
                    ? null
                    : pag3,
              ),
            );
          },
        ),
        leadingWidth: 230,
        actions: [
          UserMenu(
            appConfig: pagAppConfig,
            showTheme: false,
            onRoleSelected: (MdlPagRole role) {
              if (kDebugMode) {
                print('Role: ${role.name}');
              }
              setState(() {
                _loggedInUser!.selectedRole = role;
                _scopeSelectorKey = UniqueKey();
                _contextRefreshKey = UniqueKey();
                _tenantRefreshKey = UniqueKey();
              });
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ribbonHeight),
          child: Column(children: [getAppContextRibbon(), getNoticeRibbon()]),
        ),
      ),
      drawer: WgtAppContextDrawer(
        loggedInUser: _loggedInUser!,
        appContext: _currentAppContext,
        title: _currentAppContext.label,
        // routeList: _currentAppContext.menuRouteList!,
      ),
      body: SafeArea(
        child: Center(
          child: CustomPaint(
            painter: NeoDotPatternPainter(
              color: Colors.grey.shade600.withAlpha(80),
            ),
            child: Center(
                child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // getAppConextBoard(widget.pageRoute),
                Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      horizontalSpaceTiny,
                      Container(
                        // full screen width
                        // width: _boardWidth,
                        width: _boardWidth,
                        alignment: Alignment.topCenter,
                        child: getAppConextBoard(widget.pageRoute),
                      ),
                    ],
                  ),
                ),
                if (_contextMenuIsStack)
                  WgtAppContextMenu(
                    loggedInUser: _loggedInUser!,
                    width: sliderWidth,
                    appContext: _currentAppContext,
                    title: _currentAppContext.label,
                    // routeList: _currentAppContext.menuRouteList!,
                    // routeList2: _currentAppContext.routeList,
                  ),
              ],
            )),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 13,
        child: Text(
          bottomText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).hintColor.withAlpha(50),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        onPressed: () {
          // updateLayout() {
          //   setState(() {
          //     _boardToReset = widget.pageRoute;
          //     // _contextRefreshKey = UniqueKey();
          //     _layoutRefreshKey = UniqueKey();
          //   });
          // }

          updateTheme() {
            setState(() {
              // _boardToReset = widget.pageRoute;
              _themeRefreshKey = UniqueKey();
            });
          }

          //find bottom right position
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset offset = renderBox.localToGlobal(Offset.zero);
          double bottom = offset.dy + renderBox.size.height;
          double right = offset.dx + renderBox.size.width;
          RelativeRect position = RelativeRect.fromLTRB(right, bottom, 0, 0);
          showMenu(
            context: context,
            position: position,
            items: [
              PopupMenuItem<int>(
                value: 2,
                // onTap: null,
                enabled: false,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return getThemeSelector(context, setState, updateTheme);
                  },
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                enabled: false,
                child: StatefulBuilder(builder: (context, setState) {
                  return getModeSelector(context, setState);
                }),
              ),
              PopupMenuItem<int>(
                value: 0,
                child: StatefulBuilder(builder: (context, setState) {
                  // wrap the menu item with StatefulBuilder so that
                  // we can update the state of the parent widget
                  // and theme color of the menu will update when theme changes
                  return ListTile(
                    leading: Icon(
                      Symbols.reset_focus,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(130),
                    ),
                    title: Text("Reset Panel Positions",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(130))),
                    onTap: () {
                      _resetPanelPositions();
                      context.pop();
                    },
                  );
                }),
              ),
            ],
            elevation: 8.0,
          ).then((value) {
            if (value != null) {
              if (kDebugMode) {
                print("You selected: $value");
              }
            }
          });
        },
        child: Icon(
          Symbols.settings,
          size: 21,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
        ),
      ),
    );
  }

  Widget buildTitleWidget() {
    if (_loggedInUser == null || _loggedInUser!.isEmpty) {
      return const SizedBox();
    }
    if (kDebugMode) {
      print('buildTitleWidget: ${_currentAppContext.name}');
    }
    // int projectCount = _loggedInUser!.getProjectProfileList().length;
    // int siteCount = _loggedInUser!.selectedProjectProfile!.getTotalSiteCount();
    return Transform.translate(
      offset: const Offset(-80, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget.icon ?? const SizedBox(),
          getScopeSelector(),
          horizontalSpaceRegular,
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).hintColor.withAlpha(80),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Text(
                  'Tenant: ',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 15,
                  ),
                ),
                WgtUserTenantSelector(
                  key: _tenantRefreshKey,
                  appConfig: pagAppConfig,
                  loggedInUser: _loggedInUser!,
                  onTenantSelected: (tenant) {
                    if (kDebugMode) {
                      print('Tenant: ${tenant?.name}');
                    }
                    setState(() {
                      _selectedTenant = tenant;
                      _contextRefreshKey = UniqueKey();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getAppConextBoard(PagPageRoute? pageRoute) {
    if (kDebugMode) {
      print('getAppContextBoard: ${_currentAppContext.name}');
    }

    // routeGuard(context, _loggedInUser, appContext: _currentAppContext);

    late Widget board;
    switch (_currentAppContext.appContextType) {
      // case PagAppContextType.consoleHome:
      //   board = WgtAppContextConsoleHome(
      //     key: _contextRefreshKey,
      //     pageRoute: pageRoute,
      //     pageToReset: _boardToReset,
      //     // onStat: _updateSiteFh,
      //   );
      case PagAppContextType.ems:
        board = WgtAppContextEms(
          key: _contextRefreshKey,
          pageRoute: pageRoute,
          selectedTenant: _selectedTenant,
        );
      default:
        board = WgtAppContextEms(
          key: _contextRefreshKey,
          pageRoute: pageRoute,
          selectedTenant: _selectedTenant,
        );
      // board = WgtAppContextConsoleHome(
      //   key: _contextRefreshKey,
      //   pageRoute: pageRoute,
      //   pageToReset: _boardToReset,
      //   // onStat: _updateSiteFh,
      // );
    }

    return board;
  }

  Widget getAppContextRibbon() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(5),
            width: 1.0,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(5),
            width: 1.0,
          ),
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        //     spreadRadius: 1,
        //     blurRadius: 5,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      height: 50.0,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [Center(child: getAppContextButtonRow())],
      ),
    );
  }

  Widget getAppContextButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: appContextList
          .map((appContext) => getAppConextButton(appContext))
          .toList(),
    );
  }

  Widget getNoticeRibbon() {
    if (!_loadingPagAppContext) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(5),
            width: 1.0,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(5),
            width: 1.0,
          ),
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        //     spreadRadius: 1,
        //     blurRadius: 5,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      height: 50.0,
      child: Center(child: getBoardNotice()),
    );
  }

  Widget getScopeSelector() {
    assert(_loggedInUser!.userScope != null);
    return WgtPagScopeSelector3(
      key: _scopeSelectorKey,
      iniScope: _loggedInUser!.selectedScope,
      projectList: _loggedInUser!.userScope!,
      onChange: (
        projectProfile,
        siteGroupProfile,
        siteProfile,
        buildingProfile,
        locatonGroupProfile,
      ) async {
        setState(() {
          _loggedInUser!.selectedScope = MdlPagScopeProfile(
            projectProfile: projectProfile,
            siteGroupProfile: siteGroupProfile,
            siteProfile: siteProfile,
            buildingProfile: buildingProfile,
            locationGroupProfile: locatonGroupProfile,
          );
          _activeScopeStr = _loggedInUser!.selectedScope.getEffectScopeStr();
          if (kDebugMode) {
            print('Active Scope: $_activeScopeStr');
          }

          _projectLogoKey = UniqueKey();
          _scopeSelectorKey = UniqueKey();
          _contextRefreshKey = UniqueKey();
          _tenantRefreshKey = UniqueKey();
        });
      },
    );
  }

  Widget getBoardNotice() {
    if (_loadingPagAppContext) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const WgtPagWait(
            size: 35,
            showCenterSquare: true,
            centerOpacity: 0.78,
            colorC: pag3,
          ),
          horizontalSpaceSmall,
          _loadingMessage.contains('OAX HyperJump')
              ? Text(
                  _loadingMessage,
                  style: TextStyle(
                    color: pagNeo,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: pagNeo.withAlpha(80),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                )
              : Text(_loadingMessage),
        ],
      );
    }
    return const SizedBox();
  }

  Widget getAppConextButton(MdlPagAppContext appContext) {
    if (_loggedInUser == null || _loggedInUser!.isEmpty) {
      return const SizedBox();
    }
    bool disabled = _loadingPagAppContext;
    if (!_loggedInUser!.selectedScope.projectProfile!.hasAppInfo(
      appContext.name,
    )) {
      disabled = true;
    }
    if (appContext.is3rdParty) {
      PlatformVendor pv = PlatformVendor.values.byName(appContext.name);
      assert(appContext.vendorCredType != null);
      String cred = _loggedInUser!.getVendorCred(
        pv,
        appContext.vendorCredType!,
      );
      if (cred.isEmpty) {
        disabled = true;
      }
    }
    if (disabled) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: InkWell(
        onTap: disabled
            ? null
            : () async {
                if (kDebugMode) {
                  print('AppContext: ${appContext.name}');
                }

                PagPageRoute? appHomeRoute = appContext.appHomePageRoute;
                String routeStr = appHomeRoute?.route ?? appContext.route;

                if (mounted) {
                  context.go('/$routeStr');
                }
              },
        child: Container(
          width: 65,
          decoration: BoxDecoration(
            color: _loadingPagAppContext
                ? Theme.of(context).hintColor.withAlpha(50)
                : appContext.appContextType == _currentAppContext.appContextType
                    ? pag3.withAlpha(210)
                    : disabled
                        ? Theme.of(context).disabledColor.withAlpha(210)
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withAlpha(210),
            borderRadius: BorderRadius.circular(5),
            border: !appContext.is3rdParty
                ? null
                : Border.all(
                    color: disabled
                        ? Theme.of(context).disabledColor.withAlpha(200)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(130),
                    width: 1.5,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appContext.shortLabel,
                style: TextStyle(
                  color: disabled
                      ? Theme.of(context).hintColor.withAlpha(210)
                      : Theme.of(context).colorScheme.onSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Scaffold homeBoard(String boardTitle, Widget contentWidget) {
  //   return Scaffold(
  //     appBar: AppBar(title: Center(child: Text(boardTitle))),
  //     body: CustomPaint(
  //       painter: NeoDotPatternPainter(
  //         color: Colors.grey.shade600.withAlpha(80),
  //       ),
  //       child: Center(child: contentWidget),
  //     ),
  //   );
  // }
  Widget getModeSelector(BuildContext context, StateSetter setState) {
    //dark and light mode
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: _isDarkMode
                ? null
                : () {
                    Provider.of<PagThemeProvider>(context, listen: false)
                        .setPrefIsDark(isDark: true);
                    setState(() {
                      _isDarkMode = true;
                    });
                  },
            child: Container(
              width: 35,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Theme.of(context).highlightColor.withAlpha(180)
                    : Theme.of(context).colorScheme.secondary.withAlpha(130),
                borderRadius: BorderRadius.circular(3),
              ),
              child:
                  const Center(child: Icon(Icons.nightlight_round, size: 20)),
            ),
          ),
          // horizontalSpaceSmall,
          InkWell(
            onTap: !_isDarkMode
                ? null
                : () {
                    Provider.of<PagThemeProvider>(context, listen: false)
                        .setPrefIsDark(isDark: false);
                    setState(() {
                      _isDarkMode = false;
                    });
                  },
            child: Container(
              width: 35,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Theme.of(context).colorScheme.secondary.withAlpha(130)
                    : Theme.of(context).highlightColor.withAlpha(180),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(child: Icon(Icons.wb_sunny, size: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget getThemeSelector(
      BuildContext context, StateSetter setState, Function updateTheme) {
    // _currentThemeKey = Provider.of<PagThemeProvider>(context, listen: false).getThemeKey();

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: _currentThemeKey == 'vivid'
                ? null
                : () {
                    Provider.of<PagThemeProvider>(context, listen: false)
                        .setPrefThemeKey(themeKey: 'vivid');
                    // context.pop();
                    setState(() {
                      // _themeRefreshKey = UniqueKey();
                      _currentThemeKey = 'vivid';
                    });
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    updateTheme.call();
                    // });
                  },
            child: Container(
              width: 75,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _currentThemeKey == 'vivid'
                    ? Theme.of(context).highlightColor.withAlpha(180)
                    : Theme.of(context).colorScheme.secondary.withAlpha(130),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  'Vivid',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          horizontalSpaceTiny,
          InkWell(
            onTap: _currentThemeKey == 'minimal'
                ? null
                : () {
                    Provider.of<PagThemeProvider>(context, listen: false)
                        .setPrefThemeKey(themeKey: 'minimal');
                    // context.pop();

                    setState(() {
                      // _themeRefreshKey = UniqueKey();
                      _currentThemeKey = 'minimal';
                    });
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    updateTheme.call();
                    // });
                  },
            child: Container(
              width: 75,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _currentThemeKey == 'minimal'
                    ? Theme.of(context).highlightColor.withAlpha(180)
                    : Theme.of(context).colorScheme.secondary.withAlpha(130),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  'Minimal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

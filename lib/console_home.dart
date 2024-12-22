import 'dart:async';
import 'dart:convert';
import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/def/def_tree.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope2.dart';
import 'package:buff_helper/pag_helper/theme/theme_setting.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_selector3.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_pag.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/show_model_bottom_sheet.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pag_ems_tp/app_context/wgt_app_context_ems.dart';
import 'package:pag_ems_tp/app_context_drawer.dart';
import 'package:pag_ems_tp/pg_project_public_front.dart';
import 'package:pag_ems_tp/pg_splash.dart';
import 'package:pag_ems_tp/user_menu.dart';
import 'package:pag_ems_tp/user_service/comm_user_service.dart';
import 'package:provider/provider.dart';
import '../app_config.dart';

class ConsoleHome extends StatefulWidget {
  const ConsoleHome({super.key, required this.pageRoute, this.icon});

  final PagPageRoute pageRoute;
  final Widget? icon;

  @override
  State<ConsoleHome> createState() => _ConsoleHomeState();
}

class _ConsoleHomeState extends State<ConsoleHome>
    with TickerProviderStateMixin {
  bool _initialised = false;

  late MdlPagUser? _loggedInUser;

  late MdlPagAppContext _currentAppContext;

  bool _loadingPagAppContext = false;
  String _loadingMessage = '';

  UniqueKey? _projectLogoKey;
  UniqueKey? _scopeSelectorKey;
  UniqueKey? _contextRefreshKey;

  late String _activeScopeStr;

  late String pageTitle;

  RenderBox? _renderBox;

  bool _showLeftSideSlider = true;
  final double sliderWidth = 250.0;
  late double _sliderLeftPosition = 0; //-sliderWidth;
  UniqueKey? _sliderRefreshKey;
  bool _leftSliderIsStack = true;
  bool _rightSliderIsStack = true;
  bool _showAppCtxMenu = true;
  bool _showSiteSelectorSlider = true;

  bool _isFetchingAppCtxData = false;
  Timer? _fhRefreshTimer;
  String _fetchedTimeStr = '';
  Timer? _refreshStrAnimTimer;
  AnimationController? _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  AnimationController? _rotationAnimationController;
  late Animation<double> _rotationAnimation;

  Future<void> loadAppSetting() async {
    try {
      _loggedInUser = await checkLoginStatus();

      if (_loggedInUser != null) {
        // _loggedInUser = user;

        if (mounted) {
          if (kDebugMode) {
            // NOTE: DO NOT USE GoRouterState.of(context).path
            // will cause rebuild issue
            // print('current route:${GoRouterState.of(context).path}');
          }
          Provider.of<PagUserProvider>(context, listen: false).currentUser =
              _loggedInUser;
        }

        if (mounted) {
          if (kDebugMode) {
            print('Fetching App Context Data on load');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      if (kDebugMode) {
        print('loadAppSetting done');
      }
      if (_loggedInUser == null) {
        if (mounted) {
          context.go('/${getRoute(PagPageRoute.projectPublicFront)}');
        }
      } else {
        if (mounted) {
          routeGuard(context, _loggedInUser, goHome: true);
        }
      }
    }
  }

  Future<MdlPagUser?> checkLoginStatus() async {
    DateTime now = DateTime.now();

    String? username = await storage.read(
      key: PagUserKey.identifier.toString(),
    );
    String? password = await storage.read(key: PagUserKey.password.toString());

    if (username == null || password == null) {
      return null;
    } else {
      try {
        MdlPagUser user = await doLoginPag(
          Map.of({
            PagUserKey.username: username,
            PagUserKey.password: password,
            PagUserKey.email: '',
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

  void _loadPref() {
    dynamic prefStr = readFromSharedPref('scope_nav_bar');
    Map<String, dynamic> pref = json.decode(prefStr ?? '{}');

    if (pref.isNotEmpty) {
      _leftSliderIsStack = pref['isStack'] ?? true;
      _showLeftSideSlider = pref['showSlider'] ?? true;
      // print('site_selector_bar: $_leftSliderIsStack, $_showLeftSideSlider');
      if (_leftSliderIsStack && !_showLeftSideSlider) {
        _sliderLeftPosition = -sliderWidth;
      }
    }
  }

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
      _renderBox = context.findRenderObject() as RenderBox;
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

    bool loggedIn = _loggedInUser != null && !_loggedInUser!.isEmpty;
    if (kDebugMode) {
      print('app_home: loggedIn: $loggedIn');
    }

    return !loggedIn
        ? FutureBuilder<void>(
          future: loadAppSetting(),
          builder: (context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                if (kDebugMode) {
                  print('waiting...');
                }
                return const PgSplash();
              default:
                if (snapshot.hasError) {
                  if (kDebugMode) {
                    print(snapshot.error);
                  }
                  return homeBoard(
                    'Error',
                    getErrorTextPrompt(
                      context: context,
                      errorText: 'Serivce Error',
                    ),
                  );
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

                    return completedWidget();
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
              onTap:
                  _loadingPagAppContext
                      ? null
                      : () {
                        Scaffold.of(context).openDrawer();
                      },
              child: WgtPaG(
                conextLabel: pageTitle, //_currentAppContext.label,
                size: 35,
                colorA: getColor(context: context, pagWgt: PagWgt.pagCube),
                colorC:
                    _currentAppContext.appContextType ==
                            PagAppContextType.consoleHome
                        ? null
                        : pag3,
              ),
            );
          },
        ),
        leadingWidth: 230,
        actions: const [UserMenu()],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ribbonHeight),
          child: Column(children: [getAppContextRibbon(), getNoticeRibbon()]),
        ),
      ),
      drawer: WgtAppContextDrawer(
        title: _currentAppContext.label,
        routeList: _currentAppContext.menuRouteList!,
      ),
      body: SafeArea(
        child: Center(
          child: CustomPaint(
            painter: NeoDotPatternPainter(
              color: Colors.grey.shade600.withAlpha(80),
            ),
            child: Center(child: getAppConextBoard(widget.pageRoute)),
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
        backgroundColor: Theme.of(context).hintColor.withAlpha(50),
        onPressed: () {
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
                value: 0,
                child: ListTile(
                  leading: Icon(
                    Symbols.reset_focus,
                    color: Theme.of(context).hintColor,
                  ),
                  title: Text(
                    "Reset Panel Positions",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  onTap: () {
                    _resetPanelPositions();
                    context.pop();
                  },
                ),
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

  Widget getFhDataUpdate() {
    bool show =
        _currentAppContext == appCtxConsoleHome ||
        widget.pageRoute == PagPageRoute.esInsights;
    if (_colorAnimationController != null &&
        _rotationAnimationController != null) {
      return !show
          ? const SizedBox()
          : AnimatedBuilder(
            animation: _colorAnimationController!,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    horizontalSpaceSmall,
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Symbols.sync,
                        size: 15,
                        color: _colorAnimation.value,
                      ),
                    ),
                    horizontalSpaceTiny,
                    _fetchedTimeStr == '-'
                        ? xtWait(
                          anim: 'horizontalRotatingDots',
                          color: _colorAnimation.value,
                        )
                        : Text(
                          _fetchedTimeStr,
                          style: TextStyle(
                            fontSize: 13.6,
                            color: _colorAnimation.value,
                          ),
                        ),
                  ],
                ),
              );
            },
          );
    }
    return const SizedBox();
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
        children: [widget.icon ?? const SizedBox(), getScopeSelector()],
      ),
    );
  }

  Widget getAppConextBoard(PagPageRoute? pageRoute) {
    if (kDebugMode) {
      print('getAppContextBoard: ${_currentAppContext.name}');
    }

    routeGuard(context, _loggedInUser, appContext: _currentAppContext);

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
        board = WgtAppContextEms(key: _contextRefreshKey, pageRoute: pageRoute);
      default:
        board = WgtAppContextEms(key: _contextRefreshKey, pageRoute: pageRoute);
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
      children:
          appContextList
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
          _loggedInUser!.selectedScope = MdlPagScope2(
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
          _contextRefreshKey = UniqueKey();
          _sliderRefreshKey = UniqueKey();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: InkWell(
        onTap:
            disabled
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
            color:
                _loadingPagAppContext
                    ? Theme.of(context).hintColor.withAlpha(50)
                    : appContext.appContextType ==
                        _currentAppContext.appContextType
                    ? pag3.withAlpha(200)
                    : disabled
                    ? Theme.of(context).disabledColor.withAlpha(200)
                    : Theme.of(context).colorScheme.primary.withAlpha(130),
            borderRadius: BorderRadius.circular(5),
            border:
                !appContext.is3rdParty
                    ? null
                    : Border.all(
                      color:
                          disabled
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
                  color:
                      disabled
                          ? Theme.of(context).hintColor.withAlpha(200)
                          : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold homeBoard(String boardTitle, Widget contentWidget) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text(boardTitle))),
      body: CustomPaint(
        painter: NeoDotPatternPainter(
          color: Colors.grey.shade600.withAlpha(80),
        ),
        child: Center(child: contentWidget),
      ),
    );
  }
}

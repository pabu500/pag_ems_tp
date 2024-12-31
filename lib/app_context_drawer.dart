import 'package:buff_helper/pag_helper/model/app/mdl_app_context_config.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_page_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:provider/provider.dart';

class WgtAppContextDrawer extends StatefulWidget {
  const WgtAppContextDrawer({
    super.key,
    required this.loggedInUser,
    required this.appContext,
    required this.title,
    // required this.routeList,
    this.tileColor,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppContext appContext;
  final String title;
  // final List<Map<String, dynamic>> routeList;

  final Color? tileColor;

  @override
  State<WgtAppContextDrawer> createState() => _WgtAppContextDrawerState();
}

class _WgtAppContextDrawerState extends State<WgtAppContextDrawer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    return Drawer(
      // width: 210,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: widget.tileColor ?? Theme.of(context).colorScheme.primary,
            ),
            margin: EdgeInsets.zero,
            child: Text(
              widget.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
              ),
            ),
          ),
          ..._buildDrawerTiles(appModel),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerTiles(PagAppProvider appModel) {
    List<MdlPagAppContextConfig> appCtxConfigList =
        widget.loggedInUser.selectedScope.projectProfile!.appContextConfigList;
    MdlPagAppContextConfig? appCtxConfigCurAppCtx;
    for (MdlPagAppContextConfig appCtxConfig in appCtxConfigList) {
      if (appCtxConfig.appContextName == widget.appContext.name) {
        appCtxConfigCurAppCtx = appCtxConfig;
        break;
      }
    }
    assert(appCtxConfigCurAppCtx != null);

    List<Widget> tiles = [];
    for (Map<String, dynamic> routeItem in widget.appContext.menuRouteList!) {
      String label = routeItem['label'];
      String route = routeItem['route'];
      PagPageRoute pr = routeItem['pr'];

      bool prFound = false;
      for (MdlPagPageConfig pc in appCtxConfigCurAppCtx!.pageConfigList) {
        if (pc.name == route) {
          prFound = true;
          break;
        }
      }
      if (!prFound) {
        continue;
      }

      tiles.add(
        ListTile(
          title: Text(
            label,
            style: TextStyle(color: getTileTextColor(pr)),
          ),
          trailing:
              Icon(Icons.arrow_right, color: getTileTextColor(pr), size: 21),
          tileColor: getToggledTileColor(pr),
          onTap: () {
            context.go('/$route');
          },
        ),
      );
    }
    return tiles;
  }

  Color getTileTextColor(PagPageRoute pr) {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    if (kDebugMode) {
      print('prCur: ${appModel.prCur}');
    }

    return appModel.prCur == pr
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onPrimary;
  }

  Color getToggledTileColor(PagPageRoute pr) {
    PagAppProvider appModel = Provider.of<PagAppProvider>(context);

    return appModel.prCur == pr
        ? Theme.of(context).colorScheme.secondary
        : widget.tileColor ?? Theme.of(context).colorScheme.primary;
  }
}

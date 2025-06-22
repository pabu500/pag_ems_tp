import 'package:buff_helper/pag_helper/def/list_helper.dart';
import 'package:buff_helper/pag_helper/def/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_ls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_config.dart';

class WgtMeterManagerHome extends StatefulWidget {
  const WgtMeterManagerHome({
    super.key,
    required this.pagAppContext,
    this.height = 600,
    this.width = 1000,
  });

  final MdlPagAppContext pagAppContext;
  final double height;
  final double width;

  @override
  State<WgtMeterManagerHome> createState() => _WgtMeterManagerHomeState();
}

class _WgtMeterManagerHomeState extends State<WgtMeterManagerHome>
    with TickerProviderStateMixin {
  late final MdlPagUser? loggedInUser;

  TabController? _tabController;
  late final List<Widget> _tabViewChildren;

  late final bool showMeterOps =
      loggedInUser!.selectedScope.isAtScopeType(PagScopeType.project);

  String? _chosenModel;

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _tabViewChildren = [
      Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: WgtPagLs(
          appConfig: pagAppConfig,
          pagAppContext: widget.pagAppContext,
          itemKind: PagItemKind.device,
          listContextType: PagListContextType.info,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: WgtPagLs(
          appConfig: pagAppConfig,
          pagAppContext: widget.pagAppContext,
          itemKind: PagItemKind.device,
          listContextType: PagListContextType.usage,
        ),
      ),
    ];

    _tabController =
        TabController(length: _tabViewChildren.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    TextStyle? tabLabelStyle =
        screenWidth > 400 ? null : const TextStyle(fontSize: 12);
    bool narrowScreen = screenWidth < 550;
    return Center(
      // NOTE: DO NOT put Column above this Column
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).hintColor,
            dividerColor: Theme.of(context).colorScheme.surface,
            tabs: [
              Tab(child: Text('Meter List/Search', style: tabLabelStyle)),
              Tab(child: Text('Meter Usage', style: tabLabelStyle)),
            ],
            // onTap: (index) {},
          ),
          // NOTE: Expanded is required
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: _tabViewChildren,
            ),
          ),
        ],
      ),
    );
  }
}

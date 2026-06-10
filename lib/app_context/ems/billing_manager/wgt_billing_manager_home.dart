import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_ls.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

import '../../../app_config.dart';
import 'wgt_eb_bill.dart';

class WgtBillingManagerHome extends StatefulWidget {
  const WgtBillingManagerHome({
    super.key,
    required this.pagAppContext,
    this.selectedTenant,
  });

  final MdlPagAppContext pagAppContext;
  final MdlPagTenant? selectedTenant;

  @override
  State<WgtBillingManagerHome> createState() => _WgtBillingManagerHomeState();
}

class _WgtBillingManagerHomeState extends State<WgtBillingManagerHome>
    with TickerProviderStateMixin {
  late final MdlPagUser? loggedInUser;

  TabController? _tabController;
  final List<Widget> _tabViewChildren = [];

  late final bool showBillLs;

  @override
  void initState() {
    super.initState();

    // assert(widget.selectedTenant != null);

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    if (widget.selectedTenant != null) {
      showBillLs = true;
    } else {
      showBillLs = false;
    }

    // _tabViewChildren.addAll([
    //   // WgtPagLs(
    //   //   appConfig: pagAppConfig,
    //   //   pagAppContext: widget.pagAppContext,
    //   //   itemKind: PagItemKind.bill,
    //   //   isCompactFinder: context.isPhone,
    //   //   listContextType: PagListContextType.infoTp,
    //   //   initialFilterMap: {
    //   //     'tenant_id': widget.selectedTenant?.id,
    //   //     'tenant_name': widget.selectedTenant?.name,
    //   //     'tenant_label': widget.selectedTenant?.label,
    //   //     'tenant_account_number': widget.selectedTenant?.accountNumber,
    //   //     // 'lc_status': 'Rl',
    //   //   },
    //   // ),
    //   SizedBox(
    //     height: 400,
    //     child: Center(
    //       child: Text(
    //         'Bill List/Search Coming Soon',
    //         style: Theme.of(context).textTheme.headlineSmall,
    //       ),
    //     ),
    //   ),
    //   WgtEbBillTenant(tenant: widget.selectedTenant),
    // ]);

    // _tabController =
    //     TabController(length: _tabViewChildren.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    _tabViewChildren.addAll([
      showBillLs
          ? WgtPagLs(
              appConfig: pagAppConfig,
              pagAppContext: widget.pagAppContext,
              itemKind: PagItemKind.bill,
              isCompactFinder: context.isPhone,
              listContextType: PagListContextType.infoTp,
              initialFilterMap: {
                'tenant_id': widget.selectedTenant?.id,
                'tenant_name': widget.selectedTenant?.name,
                'tenant_label': widget.selectedTenant?.label,
                'tenant_account_number': widget.selectedTenant?.accountNumber,
                // 'lc_status': 'Rl',
              },
            )
          : SizedBox(
              height: 400,
              child: Center(
                child: Text(
                  'Select tenant to view bills',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).hintColor.withAlpha(130),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      WgtEbBillTenant(tenant: widget.selectedTenant),
    ]);

    _tabController =
        TabController(length: _tabViewChildren.length, vsync: this);

    double screenWidth = MediaQuery.of(context).size.width;
    TextStyle? tabLabelStyle =
        screenWidth > 400 ? null : const TextStyle(fontSize: 12);
    bool narrowScreen = screenWidth < 550;
    return Center(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).hintColor,
            dividerColor: Theme.of(context).colorScheme.surface,
            tabs: [
              Tab(child: Text('List/Search Bill', style: tabLabelStyle)),
              Tab(child: Text('EB Bill', style: tabLabelStyle)),
            ],
            onTap: (index) {},
          ),
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

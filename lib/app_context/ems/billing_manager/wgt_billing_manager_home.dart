import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/material.dart';

import 'wgt_eb_bill.dart';
import 'wgt_tenant_bill_list.dart';

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
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = widget.selectedTenant?.id;
    final tabViewChildren = <Widget>[
      // widget.selectedTenant != null
      //     ? WgtPagLs(
      //         key: ValueKey('bill-search-$tenantId'),
      //         appConfig: pagAppConfig,
      //         pagAppContext: widget.pagAppContext,
      //         itemKind: PagItemKind.bill,
      //         isCompactFinder: context.isPhone,
      //         listContextType: PagListContextType.infoTp,
      //         initialFilterMap: {
      //           'tenant_id': widget.selectedTenant?.id,
      //           'tenant_name': widget.selectedTenant?.name,
      //           'tenant_label': widget.selectedTenant?.label,
      //           'tenant_account_number': widget.selectedTenant?.accountNumber,
      //           // 'lc_status': 'Rl',
      //         },
      //       )
      //     : SizedBox(
      //         height: 400,
      //         child: Center(
      //           child: Text(
      //             'Select tenant to view bills',
      //             style: TextStyle(
      //               fontSize: 25,
      //               color: Theme.of(context).hintColor.withAlpha(130),
      //               fontWeight: FontWeight.w600,
      //             ),
      //           ),
      //         ),
      //       ),
      widget.selectedTenant != null
          ? WgtTenantBillList(
              key: ValueKey('tenant-bills-$tenantId'),
              pagAppContext: widget.pagAppContext,
              tenant: widget.selectedTenant,
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
      WgtEbBillTenant(
        key: ValueKey('eb-bills-$tenantId'),
        tenant: widget.selectedTenant,
      ),
    ];

    double screenWidth = MediaQuery.of(context).size.width;
    TextStyle? tabLabelStyle =
        screenWidth > 400 ? null : const TextStyle(fontSize: 12);
    return Center(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).hintColor,
            dividerColor: Theme.of(context).colorScheme.surface,
            tabs: [
              // Tab(child: Text('List/Search Bill', style: tabLabelStyle)),
              Tab(child: Text('Tenant Bill', style: tabLabelStyle)),
              Tab(child: Text('EB Bill', style: tabLabelStyle)),
            ],
            onTap: (index) {},
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: tabViewChildren,
            ),
          ),
        ],
      ),
    );
  }
}

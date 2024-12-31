import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/material.dart';

import 'wgt_eb_bill.dart';

class WgtBillingManagerHome extends StatefulWidget {
  const WgtBillingManagerHome({
    super.key,
    required this.pagAppContext,
  });

  final MdlPagAppContext pagAppContext;

  @override
  State<WgtBillingManagerHome> createState() => _WgtBillingManagerHomeState();
}

class _WgtBillingManagerHomeState extends State<WgtBillingManagerHome>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late final List<Widget> _tabViewChildren;

  @override
  void initState() {
    super.initState();

    _tabViewChildren = [
      const WgtEbBillTenant(
        tenantIdStr: '123',
        tenenatName: 'tenant-1', //'admin'
        tenantLabel: 'Tenant 1',
        tenantAccountNumber: 'A5310014',
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
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).hintColor,
            dividerColor: Theme.of(context).colorScheme.surface,
            tabs: [
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

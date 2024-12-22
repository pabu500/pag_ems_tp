import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_context/wgt_billing_manager.dart';
import 'wgt_ems_dashboard.dart';

class WgtAppContextEms extends StatelessWidget {
  const WgtAppContextEms({super.key, this.pageRoute});

  final PagPageRoute? pageRoute;

  @override
  Widget build(BuildContext context) {
    return getRoutePage();
  }

  Widget getRoutePage() {
    switch (pageRoute) {
      case PagPageRoute.emsDashboard:
        return const WgtEmsDashboard();
      case PagPageRoute.billingManager:
        return const WgtBillingManager();
      default:
        return const WgtEmsDashboard();
    }
  }
}

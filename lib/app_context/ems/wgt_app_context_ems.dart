import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_context/ems/billing_manager/wgt_billing_manager_home.dart';

class WgtAppContextEms extends StatelessWidget {
  const WgtAppContextEms({super.key, this.pageRoute});

  final PagPageRoute? pageRoute;

  @override
  Widget build(BuildContext context) {
    return getRoutePage();
  }

  Widget getRoutePage() {
    switch (pageRoute) {
      case PagPageRoute.billingManager:
        return WgtBillingManagerHome(pagAppContext: appCtxEms);
      default:
        return WgtBillingManagerHome(pagAppContext: appCtxEms);
    }
  }
}

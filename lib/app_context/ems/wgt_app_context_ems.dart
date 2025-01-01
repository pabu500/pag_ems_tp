import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_context/ems/billing_manager/wgt_billing_manager_home.dart';

class WgtAppContextEms extends StatelessWidget {
  const WgtAppContextEms({
    super.key,
    this.pageRoute,
    this.selectedTenant,
  });

  final PagPageRoute? pageRoute;
  final MdlPagTenant? selectedTenant;

  @override
  Widget build(BuildContext context) {
    return getRoutePage();
  }

  Widget getRoutePage() {
    switch (pageRoute) {
      case PagPageRoute.billingManager:
        return WgtBillingManagerHome(
            pagAppContext: appCtxEms, selectedTenant: selectedTenant);
      default:
        return WgtBillingManagerHome(
            pagAppContext: appCtxEms, selectedTenant: selectedTenant);
    }
  }
}

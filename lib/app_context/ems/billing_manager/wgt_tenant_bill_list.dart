import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_ls.dart';
import 'package:flutter/material.dart';

import '../../../app_config.dart';

class WgtTenantBillList extends StatelessWidget {
  const WgtTenantBillList({
    super.key,
    required this.pagAppContext,
    required this.tenant,
  });

  final MdlPagAppContext pagAppContext;
  final MdlPagTenant? tenant;

  @override
  Widget build(BuildContext context) {
    if (tenant == null) {
      return SizedBox(
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
      );
    }

    return WgtPagLs(
      appConfig: pagAppConfig,
      pagAppContext: pagAppContext,
      itemKind: PagItemKind.bill,
      listContextType: PagListContextType.infoTp,
      initialNoR: 5,
      showFinder: false,
      loadOnInit: true,
      sortBy: 'created_timestamp',
      sortOrder: 'desc',
      initialFilterMap: {
        'tenant_id': tenant!.id,
        'tenant_name': tenant!.name,
        'tenant_label': tenant!.label,
        'tenant_account_number': tenant!.accountNumber,
      },
    );
  }
}

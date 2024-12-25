import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_context/wgt_eb_bill.dart';

class WgtEmsDashboard extends StatefulWidget {
  const WgtEmsDashboard({
    super.key,
  });

  @override
  State<WgtEmsDashboard> createState() => _WgtEmsDashboardState();
}

class _WgtEmsDashboardState extends State<WgtEmsDashboard> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceLarge,
          SizedBox(
            //full width,
            width: double.infinity,
            height: 800,
            child: WgtEbBillTenant(
              tenantIdStr: '123',
              tenenatName: 'tenant-1',
              tenantLabel: 'Tenant 1',
            ),
          ),
        ],
      ),
    );
  }
}

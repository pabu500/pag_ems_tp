import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtBillingManager extends StatefulWidget {
  const WgtBillingManager({
    super.key,
  });

  @override
  State<WgtBillingManager> createState() => _WgtBillingManagerState();
}

class _WgtBillingManagerState extends State<WgtBillingManager> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceLarge,
          Text(
            'Billing Manager',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

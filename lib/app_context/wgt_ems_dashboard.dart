import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

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
            child: Center(
              child: Text(
                'EMS - Dashboard',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

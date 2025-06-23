import 'package:buff_helper/pag_helper/def/list_helper.dart';
import 'package:buff_helper/pag_helper/def/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_ls.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_config.dart';

class WgtMeterManagerHome extends StatefulWidget {
  const WgtMeterManagerHome({
    super.key,
    this.selectedTenant,
    required this.pagAppContext,
    this.height = 600,
    this.width = 1000,
  });

  final MdlPagTenant? selectedTenant;
  final MdlPagAppContext pagAppContext;
  final double height;
  final double width;

  @override
  State<WgtMeterManagerHome> createState() => _WgtMeterManagerHomeState();
}

class _WgtMeterManagerHomeState extends State<WgtMeterManagerHome>
    with TickerProviderStateMixin {
  late final MdlPagUser? loggedInUser;

  TabController? _tabController;
  late List<Widget> _tabViewChildren = [];

  final List<Map<String, dynamic>> _tenantMeterInfoList = [];

  late final bool showMeterOps =
      loggedInUser!.selectedScope.isAtScopeType(PagScopeType.project);

  bool _isTenantMeterListLoaded = false;

  Future<dynamic> _getTenantMeterList() async {
    if (widget.selectedTenant == null) {
      return [];
    }

    try {
      final result = await doGetTenantMeterList(queryMap);
      final List<Map<String, dynamic>> meterList = result['meterList'] ?? [];
      _tenantMeterInfoList.clear();
      _tenantMeterInfoList.addAll(meterList);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tenant meter list: $e');
      }
    } finally {
      _isTenantMeterListLoaded = true;

      if (kDebugMode) {
        print('Tenant meter list loaded: ${_tenantMeterInfoList.length}');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _tabViewChildren = [];

    _tabController =
        TabController(length: _tabViewChildren.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    TextStyle? tabLabelStyle =
        screenWidth > 400 ? null : const TextStyle(fontSize: 12);
    bool narrowScreen = screenWidth < 550;

    bool pullData = widget.selectedTenant != null && !_isTenantMeterListLoaded;

    return Center(
      // NOTE: DO NOT put Column above this Column
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).hintColor,
            dividerColor: Theme.of(context).colorScheme.surface,
            tabs: [
              Tab(child: Text('Meter List/Search', style: tabLabelStyle)),
              Tab(child: Text('Meter Usage', style: tabLabelStyle)),
            ],
            // onTap: (index) {},
          ),
          // NOTE: Expanded is required
          Expanded(
              child: widget.selectedTenant == null
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: screenHeight > 120
                          ? screenHeight - 120
                          : screenHeight,
                      child: Center(
                        child: Text(
                          'Please select tenant',
                          style: TextStyle(
                            fontSize: 21,
                            color: Theme.of(context).hintColor.withAlpha(80),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  : pullData
                      ? FutureBuilder(
                          future: _getTenantMeterList().then((_) {
                            if (mounted) {
                              setState(() {
                                _tabViewChildren = [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: WgtPagLs(
                                      appConfig: pagAppConfig,
                                      pagAppContext: widget.pagAppContext,
                                      itemKind: PagItemKind.device,
                                      listContextType: PagListContextType.info,
                                      selectedItemInfoList:
                                          _tenantMeterInfoList,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: WgtPagLs(
                                      appConfig: pagAppConfig,
                                      pagAppContext: widget.pagAppContext,
                                      itemKind: PagItemKind.device,
                                      listContextType: PagListContextType.usage,
                                      selectedItemInfoList:
                                          _tenantMeterInfoList,
                                    ),
                                  ),
                                ];
                              });
                            }
                          }),
                          builder: (context, snapshot) {
                            switch (snapshot.connectionState) {
                              case ConnectionState.waiting:
                                if (kDebugMode) {
                                  print('waiting...');
                                }
                                return const Align(
                                  alignment: Alignment.topCenter,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [WgtPagWait(size: 35)],
                                  ),
                                );
                              // return getCompletedWidget();
                              default:
                                if (snapshot.hasError) {
                                  if (kDebugMode) {
                                    print(snapshot.error);
                                  }
                                  return getErrorTextPrompt(
                                      context: context,
                                      errorText: 'Serivce Error');
                                } else {
                                  return getCompletedWidget();
                                }
                            }
                          })
                      : getCompletedWidget()),
        ],
      ),
    );
  }

  Widget getCompletedWidget() {
    if (_tenantMeterList.isEmpty) {
      return Center(
        child: Text(
          'No meters found for this tenant',
          style: TextStyle(
            fontSize: 21,
            color: Theme.of(context).hintColor.withAlpha(80),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _tabController,
      children: _tabViewChildren,
    );
  }
}

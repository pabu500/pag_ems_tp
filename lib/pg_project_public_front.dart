import 'package:buff_helper/pag_helper/model/provider/pag_app_provider.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_config_dep.dart';

class PgProjectPublicFront extends StatefulWidget {
  const PgProjectPublicFront({super.key, this.isSplash = false});

  final bool isSplash;

  @override
  State<PgProjectPublicFront> createState() => _PgProjectPublicFrontState();
}

class _PgProjectPublicFrontState extends State<PgProjectPublicFront> {
  final maxWidth = 500.0;

  //
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('PgProjectPublicFront.build()');
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    String appVer = Provider.of<PagAppProvider>(context).appVer ?? '';
    final bottomText = '$productName $appVer $copyRightYear $productOrgName';

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.13,
            child: Container(
              height: screenHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                image: DecorationImage(
                  // opacity: 0.67,
                  image: Theme.of(context).brightness == Brightness.dark
                      ? const AssetImage("assets/images/grid3bc.png")
                      : const AssetImage("assets/images/grid3wc.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(
            height: screenHeight > 950 ? 950 : screenHeight,
            width: 0.9 * screenWidth > maxWidth ? maxWidth : 0.9 * screenWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(flex: 21, child: Container()),
                SizedBox(
                  width: 360,
                  height: 320,
                  child: Column(
                    children: [
                      Container(
                        height: 102,
                        width: 350,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              "assets/images/energy_at_grid_logo.png",
                            ),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      verticalSpaceSmall,
                      SizedBox(
                        height: 160,
                        child: widget.isSplash
                            ? const Center(child: WgtPagWait(size: 55))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Welcome to Energy@Grid',
                                    style: TextStyle(
                                      // wordSpacing: -0.5,
                                      // letterSpacing: -0.8,
                                      fontSize: 21,
                                      color: Theme.of(context).hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  verticalSpaceSmall,
                                  Text(
                                    'Tenant Portal',
                                    style: TextStyle(
                                      // wordSpacing: -0.5,
                                      // letterSpacing: -0.8,
                                      fontSize: 21,
                                      color: Theme.of(context).hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  verticalSpaceRegular,
                                  xtButton(
                                    onPressed: () => context.go('/login'),
                                    text: 'Login',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(200),
                                    textStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 21,
                                    ),
                                    shadowColor: Colors.transparent,
                                  ),
                                ],
                              ),
                      ),
                      verticalSpaceRegular,
                      verticalSpaceRegular,
                    ],
                  ),
                ),
                Flexible(flex: 6, child: Container()),
                Expanded(child: Container()),
                InkWell(
                  onTap: () => context.go('/privacy_policy'),
                  child: Text(
                    'Privacy Policy | Terms of Use',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                verticalSpaceTiny,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 13,
        child: Tooltip(
          waitDuration: const Duration(milliseconds: 500),
          message: pagAppConfig.oreSvcEnv,
          child: Text(
            bottomText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        ),
      ),
    );
  }
}

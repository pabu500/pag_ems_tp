import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PgSplash extends StatefulWidget {
  const PgSplash({super.key});

  @override
  State<PgSplash> createState() => _PgSplashState();
}

class _PgSplashState extends State<PgSplash> {
  // final _storage = const FlutterSecureStorage();
  final String keyIdentifier = PagUserKey.identifier.toString();
  final String keyPassword = PagUserKey.password.toString();
  // PagUser? _user;
  // PagAppModel get _appModel => Provider.of<PagAppModel>(context, listen: false);

  Future<void> loadAclSetting() async {
    try {
      // await getAclSetting(paGridAppConfig).then((value) {
      //   setState(() {
      //     _appModel.aclSetting = value;
      //   });
      // });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      if (kDebugMode) {
        // print('aclSetting: ${_appModel.aclSetting}');
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 95),
            Container(
              height: 200,
              width: 350,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/energy_at_grid_logo.png"),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: WgtPagWait(size: 55),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/xt_ui/painter/pag_bg_painter.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pag_ems_tp/app_config.dart';
import 'wgt_login.dart';

class PgLogin extends StatefulWidget {
  const PgLogin({super.key});

  @override
  State<PgLogin> createState() => _PgLoginState();
}

class _PgLoginState extends State<PgLogin> {
  String _oreStatus = '';
  bool _isCheckingOresvc = false;
  String _pqStatus = '';
  bool _isCheckingPQ = false;
  String _oaxsvcStatus = '';
  bool _isCheckingOaxsvc = false;
  String _ctLabStatus = '';
  bool _isCheckingCtLab = false;
  String _fleetHealthStatus = '';
  bool _isCheckingFleetHealth = false;

  bool _isChecking = false;
  bool _allSystemGo = false;

  Future<dynamic> _onPostLogin(MdlPagUser loggedInUser) async {
    try {
      setState(() {
        _isChecking = true;
        _allSystemGo = false;
      });

      if (kDebugMode) {
        print('Checking all systems');
      }

      await _checkOresvc();
      await _checkFleetHealth();
      await _checkPQ();
      await _checkOaxsvc();

      await Future.delayed(const Duration(microseconds: 500));
      setState(() {
        _allSystemGo =
            _oreStatus == 'Go' &&
            _oaxsvcStatus == 'Go' &&
            _ctLabStatus == 'Go' &&
            _fleetHealthStatus == 'Go';
      });
      await Future.delayed(const Duration(microseconds: 1000));
      if (kDebugMode) {
        print('_allSystemGo: $_allSystemGo');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isChecking = false;
      });
      if (kDebugMode) {
        print('login: finally');
      }
    }
  }

  Future<dynamic> _checkOresvc() async {
    var result = {};
    try {
      setState(() {
        _isCheckingOresvc = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      result['status'] = 'Go';
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isCheckingOresvc = false;
        _oreStatus = result['status'];
      });
    }
  }

  Future<dynamic> _checkFleetHealth() async {
    var result = {};
    try {
      setState(() {
        _isCheckingFleetHealth = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      result['status'] = 'Go';
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isCheckingFleetHealth = false;
        _fleetHealthStatus = result['status'];
      });
    }
  }

  Future<dynamic> _checkPQ() async {
    var result = {};
    try {
      setState(() {
        _isCheckingPQ = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      result['status'] = 'Go';
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isCheckingPQ = false;
        _pqStatus = result['status'];
      });
    }
  }

  Future<dynamic> _checkOaxsvc() async {
    var result = {};
    try {
      setState(() {
        _isCheckingOaxsvc = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      result['status'] = 'Go';
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isCheckingOaxsvc = false;
        _oaxsvcStatus = result['status'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('PgLogin.initState()');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('PgLogin.build()');
    }
    return Scaffold(
      body: CustomPaint(
        painter: NeoDotPatternPainter(
          color: Colors.grey.shade600.withAlpha(80),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WgtLogin(onPostLogin: _onPostLogin),
              verticalSpaceSmall,
              _allSystemGo
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.green.shade600),
                    ),
                    child: Text(
                      'All Systems Go',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        // fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : getGoStatusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getGoStatusRow() {
    if (!_isChecking) {
      return Container();
    }
    if (kDebugMode) {
      print('getGoStatusRow');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getGoStatus('ORE', _isCheckingOresvc, _oreStatus),
        horizontalSpaceSmall,
        getGoStatus('FH', _isCheckingFleetHealth, _fleetHealthStatus),
        horizontalSpaceSmall,
        getGoStatus('PQ', _isCheckingPQ, _pqStatus),
        horizontalSpaceSmall,
        getGoStatus('OAX', _isCheckingOaxsvc, _oaxsvcStatus),
        horizontalSpaceSmall,
        getGoStatus('CT LAB', _isCheckingCtLab, _ctLabStatus),
      ],
    );
  }

  Widget getGoStatus(String itemLabel, bool isChecking, String status) {
    return Row(
      children: [
        Text(
          itemLabel,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        horizontalSpaceTiny,
        isChecking
            ? const WgtPagWait(size: 21)
            : status.isEmpty
            ? Container()
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color:
                      status == 'Go'
                          ? Colors.green.shade600
                          : Theme.of(context).colorScheme.error,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  // fontStyle: FontStyle.italic,
                ),
              ),
            ),
      ],
    );
  }
}

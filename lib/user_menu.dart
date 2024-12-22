import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/pagrid_helper/user_helper/comm_sso.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserMenu extends StatefulWidget {
  const UserMenu({super.key});

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  @override
  Widget build(BuildContext context) {
    ThemeProvider themeNotifier = Provider.of<ThemeProvider>(context);

    bool isLoggedIn = true;
    MdlPagUser? user = Provider.of<PagUserProvider>(context).currentUser;
    if (user == null) {
      isLoggedIn = false;
    }

    bool checkProfile = true;
    if (isLoggedIn) {
      // // if (user!.isAdminAndUp()) {
      // if (user!.useOpsDashboard()) {
      //   checkProfile = true;
      // } else {
      //   checkProfile = user.checkPermission2(
      //       AclScope.self, AclTarget.evs2user_p_profile, AclOperation.read);
      // }
      // if (user.hasRole2(AclRole.EVS2_Basic_Meter_Consumer)) {
      //   checkProfile = false;
      // }
    }

    String username = isLoggedIn ? user!.username ?? '' : '';

    return Row(
      children: [
        Text(
          username,
          style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor),
        ),
        getUserMenu(checkProfile, isLoggedIn, themeNotifier),
      ],
    );
  }

  Widget getUserMenu(
    bool checkProfile,
    bool isLoggedIn,
    ThemeProvider themeNotifier,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person),
      onSelected: (item) => onSelected(context, item, themeNotifier),
      itemBuilder:
          (context) => [
            const PopupMenuItem<String>(
              value: 'dashboard',
              child: Text('Dashboard'),
            ),
            if (checkProfile)
              const PopupMenuItem<String>(
                value: 'myProfile',
                child: Text('My Profile'),
              ),
            // PopupMenuItem<String>(
            //   value: 'settings',
            //   child: Text('Settings'),
            // ),
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  themeNotifier.isDark
                      ? Icon(
                        Icons.wb_sunny,
                        color: Theme.of(context).primaryColorLight,
                      )
                      : Icon(
                        Icons.nightlight_round,
                        color: Theme.of(context).primaryColorDark,
                      ),
                  const SizedBox(width: 8),
                  Text(themeNotifier.isDark ? "Light Mode" : "Dark Mode"),
                ],
              ),
            ),
            if (isLoggedIn) const PopupMenuDivider(),
            if (isLoggedIn)
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sign Out'),
                  ],
                ),
              ),
          ],
    );
  }
}

void onSelected(
  BuildContext context,
  String item,
  ThemeProvider themeNotifier,
) {
  // ThemeModel themeNotifier = Provider.of<ThemeModel>(context);
  switch (item) {
    case 'myProfile':
      context.go('/my_profile');
      return;
    case 'dashboard':
      MdlPagUser? user =
          Provider.of<PagUserProvider>(context, listen: false).currentUser;
      if (user == null) {
        context.go('/project_public_front');
        return;
      }
      context.go('/console_home_dashboard');
      break;
    case 'theme':
      themeNotifier.isDark = !themeNotifier.isDark;
      break;
    case 'logout':
      storage.deleteAll();
      MdlPagUser? user =
          Provider.of<PagUserProvider>(context, listen: false).currentUser;
      if (user != null) {
        user.logout();
      }
      logoutSso(context);

      context.go('/project_public_front');
      break;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/dashboard_view.dart';
import 'package:lbpool/views/legal_view.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/match_view.dart';
import 'package:lbpool/views/players_view.dart';
import 'package:lbpool/views/rules_view.dart';
import 'package:lbpool/widgets/drawer_item.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key, required this.context});

  final BuildContext context;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<int> _getUserId() async {
    String? userFromStorage = await _storage.read(key: 'userId');
    return StringUtils.parseInt(userFromStorage);
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<int>(
      future: _getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erreur : ${snapshot.error}');
        }
        final userId = snapshot.data ?? 0;
        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DrawerItem(context: context, title: 'Dashboard', iconData: Icons.dashboard, destination: DashboardView(playerId: userId, isSelf: true,)),
                DrawerItem(context: context, title: 'Players', iconData: Icons.person, destination: PlayersView()),
                DrawerItem(context: context, title: 'Match', iconData: Icons.compare_arrows, destination: MatchView()),
                // DrawerItem(context: context, title: 'Tournament', iconData: Icons.account_tree, destination: MatchView()),
                // DrawerItem(context: context, title: 'Championship', iconData: Icons.emoji_events, destination: MatchView()),
                // DrawerItem(context: context, title: 'Feed', iconData: Icons.newspaper, destination: MatchView()),
                DrawerItem(context: context, title: 'Rules', iconData: Icons.local_library, destination: RulesView()),
                DrawerItem(context: context, title: 'Legal', iconData: Icons.copyright, destination: LegalView()),
                DrawerItem(context: context, title: 'Log out', iconData: Icons.logout, destination: LoginView()),
              ],
            )
          ),
        );
      },
    );
  }
}
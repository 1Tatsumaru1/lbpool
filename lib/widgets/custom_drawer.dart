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
  const CustomDrawer({super.key, required this.context, required this.selectedRoute});

  final BuildContext context;
  final String selectedRoute;
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

        List<Map<String, dynamic>> routes = [
          {'name': 'Dashboard', 'iconData': Icons.dashboard, 'screen': DashboardView(playerId: userId, isSelf: true,)},
          {'name': 'Players', 'iconData': Icons.person, 'screen': PlayersView()},
          {'name': 'Match', 'iconData': Icons.compare_arrows, 'screen': MatchView()},
          {'name': 'Rules', 'iconData': Icons.local_library, 'screen': RulesView()},
          {'name': 'License', 'iconData': Icons.copyright, 'screen': LegalView()},
          {'name': 'Log out', 'iconData': Icons.logout, 'screen': LoginView()},
        ];

        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: routes.map((r) {
                return DrawerItem(
                  context: context,
                  title: r['name'],
                  iconData: r['iconData'],
                  destination: r['screen'],
                  isSelected: (selectedRoute == r['name']),
                );
              }).toList()
              
              //  [
              //   DrawerItem(context: context, title: 'Dashboard', iconData: Icons.dashboard, destination: DashboardView(playerId: userId, isSelf: true,)),
              //   DrawerItem(context: context, title: 'Players', iconData: Icons.person, destination: PlayersView()),
              //   DrawerItem(context: context, title: 'Match', iconData: Icons.compare_arrows, destination: MatchView()),
              //   // DrawerItem(context: context, title: 'Feed', iconData: Icons.newspaper, destination: MatchView()),
              //   DrawerItem(context: context, title: 'Rules', iconData: Icons.local_library, destination: RulesView()),
              //   DrawerItem(context: context, title: 'License', iconData: Icons.copyright, destination: LegalView()),
              //   DrawerItem(context: context, title: 'Log out', iconData: Icons.logout, destination: LoginView()),
              // ],
            )
          ),
        );
      },
    );
  }
}
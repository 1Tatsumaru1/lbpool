import 'package:flutter/material.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/dashboard_view.dart';
import 'package:lbpool/views/match_view.dart';
import 'package:lbpool/views/players_view.dart';


class MatchResultView extends StatelessWidget {
  const MatchResultView({super.key, required this.origin, required this.elo, required this.userId});

  final String origin;
  final Map<String, dynamic> elo;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final bool won = StringUtils.parseBool(elo['won']);
    final Color color = won ? Colors.lightGreenAccent : Colors.red;
    final IconData icon = won ? Icons.check_circle_outline : Icons.sentiment_dissatisfied;
    final String message = won ? 'WON' : 'LOST';
    final String ending = won ? ' !' : '...';
    final String rankEvolution = StringUtils.parseBool(elo['rank_changed'])
      ? won ? 'Congrats ! Your rank went up !' : 'Oh no ! Your rank went down...'
      : '';
    final String newRank = StringUtils.parseInt(elo['new_rank']).toString();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Match result"),
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
    
            // 1st row : icon
            Icon(icon, size: 100, color: color),
    
            // 2nd row : points won / lost
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'You $message ',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                ),
                Text(
                  StringUtils.parseInt(elo['added']).abs().toString(),
                  style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' points$ending',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total of your points : ',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                ),
                Text(
                  elo['total'].toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10,),
            Text(
              rankEvolution,
              style: TextStyle(color: color, fontSize: 16),
            ),
            Text(
              'Your rank is $newRank',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
            ),
            const SizedBox(height: 10,),
            ElevatedButton.icon(
              label: const Text('Dashboard'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => DashboardView(playerId: userId, isSelf: true))); },
              icon: const Icon(Icons.dashboard),
            ),
            const SizedBox(height: 10,),
            ElevatedButton.icon(
              label: const Text('Players'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PlayersView())); },
              icon: const Icon(Icons.person),
            ),
            const SizedBox(height: 10,),
            ElevatedButton.icon(
              label: const Text('Match'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MatchView())); },
              icon: const Icon(Icons.compare_arrows),
            )
          ],
        )
      )
    );
  }
}
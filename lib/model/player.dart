import 'package:lbpool/services/string_utils.dart';

class Player {
  final int id;
  final String name;
  final int elo;
  final int rank;
  final int totalMatches;
  final int wins;
  final double winRate;

  Player({required this.id, required this.name, required this.elo, required this.rank, required this.totalMatches, 
    required this.wins, required this.winRate});

  static Player? createFromMap(Map<String, dynamic> userMap) {
    try {
      return Player(
        id: StringUtils.parseInt(userMap['id']),
        name: userMap['name'],
        elo: StringUtils.parseInt(userMap['elo']),
        rank: StringUtils.parseInt(userMap['rank']),
        totalMatches: StringUtils.parseInt(userMap['total_matches']),
        wins: StringUtils.parseInt(userMap['wins']),
        winRate: StringUtils.parseDouble(userMap['win_rate'] ?? 0),
      );
    } catch(e) {
      return null;
    }
  }
}
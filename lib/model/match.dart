import 'package:lbpool/services/string_utils.dart';

class Match {
  int? id;
  final int p1Id;
  final int p2Id;
  final String p1Name;
  final String p2Name;
  int? winnerId;
  int? remaining;
  bool? forfeit;
  final String startTime;
  int? daysToWait;
  int? reward;

  Match({required this.p1Id, required this.p2Id, required this.p1Name, required this.p2Name, required this.startTime,
    this.id, this.winnerId, this.forfeit, this.remaining, this.daysToWait, this.reward});

  static Match? createFromMap(Map<String, dynamic> matchMap) {
    try {
      return Match(
        id: StringUtils.parseInt(matchMap['id']),
        p1Id: StringUtils.parseInt(matchMap['player1_id']),
        p2Id: StringUtils.parseInt(matchMap['player2_id']),
        p1Name: matchMap['p1_name'],
        p2Name: matchMap['p2_name'],
        startTime: matchMap['start_time'],
        daysToWait: _daysTillMatch(matchMap['start_time']),
        winnerId: matchMap['winner_id'] == null 
          ? null 
          : StringUtils.parseInt(matchMap['winner_id']),
        remaining: matchMap['remaining'] == null 
          ? null 
          : StringUtils.parseInt(matchMap['remaining']),
        reward: matchMap['reward'] == null 
          ? null 
          : StringUtils.parseInt(matchMap['reward']),
        forfeit: matchMap['is_forfeit'] == null 
          ? null 
          : StringUtils.parseInt(matchMap['is_forfeit']) == 0 
            ? false 
            : true,
      );
    } catch(e) {
      return null;
    }
  }

  static int _daysTillMatch(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return date.difference(DateTime.now()).inDays;
  }
}
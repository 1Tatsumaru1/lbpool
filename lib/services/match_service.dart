import 'http_service.dart';

class MatchService {
  final HttpService httpService;

  MatchService({required this.httpService});

  /// Get all players and their basic stats
  Future<Map<String, dynamic>> getPlayers() async {
    final Map<String, dynamic> result = await httpService.get('/match/getPlayers');
    return result;
  }

  /// Get all matches for the given player, defaults to current player
  Future<Map<String, dynamic>> getMatchesByPlayer(int? playerId) async {
    final Map<String, dynamic> result;
    if (playerId == null) {
      result = await httpService.get('/match/getMatchesByPlayer');
    } else {
      result = await httpService.get('/match/getMatchesByPlayer/$playerId');
    }
    return result;
  }

  /// Get elo history for the given player, defaults to current player
  Future<Map<String, dynamic>> getEloHistoryByPlayer(int? playerId) async {
    final Map<String, dynamic> result;
    if (playerId == null) {
      result = await httpService.get('/match/getEloHistoryByPlayer');
    } else {
      result = await httpService.get('/match/getEloHistoryByPlayer/$playerId');
    }
    return result;
  }

  /// Get stats for the given player, defaults to current player
  Future<Map<String, dynamic>> getStatsSinglePlayer(int? playerId) async {
    final Map<String, dynamic> result;
    if (playerId == null) {
      result = await httpService.get('/match/getStatsSinglePlayer');
    } else {
      result = await httpService.get('/match/getStatsSinglePlayer/$playerId');
    }
    return result;
  }

  /// Get general stats
  Future<Map<String, dynamic>> getStatsAll() async {
    final Map<String, dynamic> result = await httpService.get('/match/getStatsAll');
    return result;
  }

  /// Create match
  Future<Map<String, dynamic>> createMatch(int p1, int p2, String startTime) async {
    final Map<String, dynamic> result = await httpService.post(
      '/match/createMatch',
      {
        'p1': p1.toString(),
        'p2': p2.toString(),
        'start': startTime
      }
    );
    return result;
  }

  /// Modify match
  Future<Map<String, dynamic>> alterMatch(int id, int p1, int p2, String startTime) async {
    final Map<String, dynamic> result = await httpService.put(
      '/match/alterMatch',
      {
        'id': id.toString(),
        'p1': p1.toString(),
        'p2': p2.toString(),
        'start': startTime
      }
    );
    return result;
  }

  /// Score a match
  Future<Map<String, dynamic>> recordMatch(int id, int winnerId, bool isForfeit, int contestLevel, int remaining) async {
    final Map<String, dynamic> result = await httpService.post(
      '/match/recordMatch',
      {
        'id': id.toString(),
        'winner_id': winnerId.toString(),
        'is_forfeit': (isForfeit) ? '1' : '0',
        'contest_level': contestLevel.toString(),
        'remaining': remaining.toString(),
      }
    );
    return result;
  }

  /// Rescore a match
  Future<Map<String, dynamic>> rescoreMatch(int id, int winnerId, bool isForfeit, int contestLevel, int remaining) async {
    final Map<String, dynamic> result = await httpService.post(
      '/match/rescoreMatch',
      {
        'id': id.toString(),
        'winner_id': winnerId.toString(),
        'is_forfeit': (isForfeit) ? '1' : '0',
        'contest_level': contestLevel.toString(),
        'remaining': remaining.toString(),
      }
    );
    return result;
  }

  /// Delete a match
  Future<Map<String, dynamic>> deleteMatch(int id) async {
    final Map<String, dynamic> result = await httpService.post(
      '/match/deleteMatch',
      {
        'id': id.toString(),
      }
    );
    return result;
  }

  // /// Change user license status
  // Future<Map<String, dynamic>> toggleUserActivationStatus(int id, int status) async {
  //   final Map<String, dynamic> result = await httpService.put(
  //     '/admin/modifyPractitionerActivityStatus',
  //     {
  //       'userId': id,
  //       'userActive': status
  //     }
  //   );
  //   return result;
  // }

  // /// Delete user account
  // Future<Map<String, dynamic>> deleteUser(int id) async {
  //   final Map<String, dynamic> result = await httpService.delete(
  //     '/admin/deletePractitioner',
  //     {
  //       'userId': id.toString()
  //     }
  //   );
  //   return result;
  // }

}

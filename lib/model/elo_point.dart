import 'package:lbpool/services/string_utils.dart';

class EloPoint {
  final String recordedAt;
  final int elo;

  EloPoint({required this.recordedAt, required this.elo});

  static EloPoint createFromMap(Map<String, dynamic> eloDot) {
    return EloPoint(
      recordedAt: eloDot['recorded_at'],
      elo: StringUtils.parseInt(eloDot['elo']),
    );
  }
}



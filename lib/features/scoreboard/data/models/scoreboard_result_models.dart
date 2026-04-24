import 'scoreboard_saved_match_record.dart';

/// 서브 설정 결과
class ScoreboardServeSetupResult {
  final int firstServerGlobalIndex;
  final int opponentFirstServerGlobalIndex;

  const ScoreboardServeSetupResult({
    required this.firstServerGlobalIndex,
    required this.opponentFirstServerGlobalIndex,
  });
}

/// 선수명 일괄 수정 결과
class ScoreboardBulkPlayerEditResult {
  final String leftPlayer1;
  final String leftPlayer2;
  final String rightPlayer1;
  final String rightPlayer2;

  const ScoreboardBulkPlayerEditResult({
    required this.leftPlayer1,
    required this.leftPlayer2,
    required this.rightPlayer1,
    required this.rightPlayer2,
  });
}

/// 저장 기록 페이지 결과
class ScoreboardSavedMatchesPageResult {
  final List<ScoreboardSavedMatchRecord> savedMatches;
  final bool changed;

  const ScoreboardSavedMatchesPageResult({
    required this.savedMatches,
    required this.changed,
  });
}

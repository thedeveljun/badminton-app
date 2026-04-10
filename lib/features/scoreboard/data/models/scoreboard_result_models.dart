import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_saved_match_record.dart';

class ScoreboardServeSetupResult {
  final int firstServerGlobalIndex;
  final int opponentFirstServerGlobalIndex;

  const ScoreboardServeSetupResult({
    required this.firstServerGlobalIndex,
    required this.opponentFirstServerGlobalIndex,
  });
}

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

class ScoreboardSavedMatchesPageResult {
  final List<ScoreboardSavedMatchRecord> savedMatches;
  final bool changed;

  const ScoreboardSavedMatchesPageResult({
    required this.savedMatches,
    required this.changed,
  });
}

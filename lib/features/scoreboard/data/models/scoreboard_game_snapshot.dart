import 'package:funminton_club_app/features/scoreboard/domain/enums/serve_side.dart';

class ScoreboardGameSnapshot {
  final int scoreA;
  final int scoreB;
  final ServeSide servingSide;
  final int leftCurrentServerIndex;
  final int rightCurrentServerIndex;
  final int leftLastServerIndex;
  final int rightLastServerIndex;
  final int leftInitialServerIndex;
  final int rightInitialServerIndex;
  final bool leftHasServed;
  final bool rightHasServed;

  const ScoreboardGameSnapshot({
    required this.scoreA,
    required this.scoreB,
    required this.servingSide,
    required this.leftCurrentServerIndex,
    required this.rightCurrentServerIndex,
    required this.leftLastServerIndex,
    required this.rightLastServerIndex,
    required this.leftInitialServerIndex,
    required this.rightInitialServerIndex,
    required this.leftHasServed,
    required this.rightHasServed,
  });
}

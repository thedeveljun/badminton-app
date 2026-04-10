import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:funminton_club_app/features/scoreboard/domain/enums/serve_side.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_game_snapshot.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_result_models.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_saved_match_record.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/pages/scoreboard_saved_matches_page.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/pages/scoreboard_bulk_player_edit_page.dart';

/// 게임 상태 + 로직 (추상 클래스)
/// ScoreboardPage 의 _ScoreboardPageState 가 이를 extends 합니다.
abstract class ScoreboardStateBase<T extends StatefulWidget> extends State<T> {
  static const String savedMatchesKey = 'saved_matches_v1';

  // ── 상태 변수 ─────────────────────────────────────────────────
  List<ScoreboardSavedMatchRecord> savedMatches = [];

  // ── TTS ──────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = true;

  Future<void> initTts() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> disposeTts() async {
    await _tts.stop();
  }

  void toggleTts() {
    _ttsEnabled = !_ttsEnabled;
    if (!_ttsEnabled) _tts.stop();
  }

  bool get ttsEnabled => _ttsEnabled;

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  // 점수 상황에 따라 읽을 텍스트 결정
  String _buildScoreAnnouncement() {
    final a = scoreA;
    final b = scoreB;

    // 게임 종료
    if (isGameFinished()) {
      return '게임! $a 대 $b';
    }

    // 듀스 상황 (둘 다 targetScore-1 이상이고 동점)
    if (useDeuce && a == b && a >= targetScore - 1) {
      return '듀스';
    }

    // 게임포인트: 한쪽이 targetScore-1점이고 상대보다 앞설 때
    final isGamePoint =
        (a == targetScore - 1 && a > b) || (b == targetScore - 1 && b > a);
    if (isGamePoint) {
      return '게임포인트! $a 대 $b';
    }

    // 듀스 게임포인트 (듀스 후 1점 차)
    if (useDeuce &&
        (a >= targetScore || b >= targetScore) &&
        (a - b).abs() == 1) {
      return '게임포인트! $a 대 $b';
    }

    // 일반 점수
    return '$a 대 $b';
  }

  int scoreA = 0;
  int scoreB = 0;
  int targetScore = 25;
  bool useDeuce = false;

  String leftPlayer1 = '선수1';
  String leftPlayer2 = '선수2';
  String rightPlayer1 = '선수3';
  String rightPlayer2 = '선수4';

  ServeSide servingSide = ServeSide.left;

  int leftCurrentServerIndex = 0;
  int rightCurrentServerIndex = 0;
  int leftLastServerIndex = 0;
  int rightLastServerIndex = 0;
  int leftInitialServerIndex = 0;
  int rightInitialServerIndex = 0;

  bool leftHasServed = false;
  bool rightHasServed = false;

  final List<ScoreboardGameSnapshot> scoreHistory = [];

  // ── 서브 상태 getters ─────────────────────────────────────────
  bool get isLeftPlayer1Serving =>
      leftHasServed &&
      servingSide == ServeSide.left &&
      leftCurrentServerIndex == 0;
  bool get isLeftPlayer2Serving =>
      leftHasServed &&
      servingSide == ServeSide.left &&
      leftCurrentServerIndex == 1;
  bool get isRightPlayer1Serving =>
      rightHasServed &&
      servingSide == ServeSide.right &&
      rightCurrentServerIndex == 0;
  bool get isRightPlayer2Serving =>
      rightHasServed &&
      servingSide == ServeSide.right &&
      rightCurrentServerIndex == 1;

  // ── 선수 helpers ──────────────────────────────────────────────
  List<String> get allPlayers => [
    leftPlayer1,
    leftPlayer2,
    rightPlayer1,
    rightPlayer2,
  ];

  bool isLeftTeamGlobalIndex(int index) => index == 0 || index == 1;
  int toLocalIndex(int globalIndex) =>
      (globalIndex == 0 || globalIndex == 2) ? 0 : 1;
  List<int> opponentCandidatesOf(int firstServerGlobalIndex) =>
      isLeftTeamGlobalIndex(firstServerGlobalIndex) ? [2, 3] : [0, 1];

  // ── 저장 helpers ──────────────────────────────────────────────
  bool _isPlaceholderLabel(String v) =>
      {'선수1', '선수2', '선수3', '선수4'}.contains(v.trim());
  String _normalizeName(String v) {
    final t = v.trim();
    return (t.isEmpty || _isPlaceholderLabel(t)) ? '' : t;
  }

  int get enteredPlayerCount => [
    leftPlayer1,
    leftPlayer2,
    rightPlayer1,
    rightPlayer2,
  ].where((n) => _normalizeName(n).isNotEmpty).length;
  bool get canSaveMatch => enteredPlayerCount >= 2;
  bool get hasEnoughScoreToSave => scoreA > 10 || scoreB > 10;
  bool get saveEnabled => canSaveMatch && hasEnoughScoreToSave;
  String get deuceLabel => useDeuce ? '듀스 ON' : '듀스 OFF';

  bool isSameRecordIgnoringTime(
    ScoreboardSavedMatchRecord a,
    ScoreboardSavedMatchRecord b,
  ) =>
      a.leftPlayer1 == b.leftPlayer1 &&
      a.leftPlayer2 == b.leftPlayer2 &&
      a.rightPlayer1 == b.rightPlayer1 &&
      a.rightPlayer2 == b.rightPlayer2 &&
      a.scoreA == b.scoreA &&
      a.scoreB == b.scoreB &&
      a.targetScore == b.targetScore &&
      a.useDeuce == b.useDeuce;

  // ── Lifecycle ─────────────────────────────────────────────────
  void initScoreboard() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    loadSavedMatches();
  }

  void disposeScoreboard() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ── 저장/불러오기 ──────────────────────────────────────────────
  Future<void> loadSavedMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(savedMatchesKey) ?? [];
    final loaded = rawList
        .map(
          (e) => ScoreboardSavedMatchRecord.fromMap(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList();
    if (!mounted) return;
    setState(() => savedMatches = loaded);
  }

  Future<void> saveCurrentMatch(String myTeamSide) async {
    final prefs = await SharedPreferences.getInstance();
    final record = ScoreboardSavedMatchRecord(
      savedAt: DateTime.now().toIso8601String(),
      leftPlayer1: leftPlayer1,
      leftPlayer2: leftPlayer2,
      rightPlayer1: rightPlayer1,
      rightPlayer2: rightPlayer2,
      scoreA: scoreA,
      scoreB: scoreB,
      targetScore: targetScore,
      useDeuce: useDeuce,
      myTeamSide: myTeamSide,
    );

    if (savedMatches.isNotEmpty &&
        isSameRecordIgnoringTime(record, savedMatches.first)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('같은 선수명, 점수, 설정으로는 바로 중복 저장할 수 없습니다'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final updated = [record, ...savedMatches];
    if (updated.length > 20) updated.removeRange(20, updated.length);

    final encoded = updated.map((e) => jsonEncode(e.toMap())).toList();
    final success = await prefs.setStringList(savedMatchesKey, encoded);

    if (!mounted) return;
    if (success) {
      setState(() => savedMatches = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('경기 기록이 저장되었습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장에 실패했습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> openSavedMatchesPage() async {
    final result = await Navigator.push<ScoreboardSavedMatchesPageResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreboardSavedMatchesPage(
          savedMatchesKey: savedMatchesKey,
          initialMatches: List<ScoreboardSavedMatchRecord>.from(savedMatches),
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.changed) setState(() => savedMatches = result.savedMatches);
  }

  // ── 게임 로직 ─────────────────────────────────────────────────
  bool isGameFinished() {
    if (scoreA >= 31 || scoreB >= 31) return true;
    if (!useDeuce) return scoreA >= targetScore || scoreB >= targetScore;
    final reached = scoreA >= targetScore || scoreB >= targetScore;
    return reached && (scoreA - scoreB).abs() >= 2;
  }

  void pushScoreSnapshot() {
    scoreHistory.add(
      ScoreboardGameSnapshot(
        scoreA: scoreA,
        scoreB: scoreB,
        servingSide: servingSide,
        leftCurrentServerIndex: leftCurrentServerIndex,
        rightCurrentServerIndex: rightCurrentServerIndex,
        leftLastServerIndex: leftLastServerIndex,
        rightLastServerIndex: rightLastServerIndex,
        leftInitialServerIndex: leftInitialServerIndex,
        rightInitialServerIndex: rightInitialServerIndex,
        leftHasServed: leftHasServed,
        rightHasServed: rightHasServed,
      ),
    );
  }

  void undoLastScore() {
    if (scoreHistory.isEmpty) return;
    setState(() {
      final last = scoreHistory.removeLast();
      scoreA = last.scoreA;
      scoreB = last.scoreB;
      servingSide = last.servingSide;
      leftCurrentServerIndex = last.leftCurrentServerIndex;
      rightCurrentServerIndex = last.rightCurrentServerIndex;
      leftLastServerIndex = last.leftLastServerIndex;
      rightLastServerIndex = last.rightLastServerIndex;
      leftInitialServerIndex = last.leftInitialServerIndex;
      rightInitialServerIndex = last.rightInitialServerIndex;
      leftHasServed = last.leftHasServed;
      rightHasServed = last.rightHasServed;
    });
  }

  void resetScores() {
    setState(() {
      scoreA = 0;
      scoreB = 0;
      servingSide = ServeSide.left;
      leftCurrentServerIndex = 0;
      rightCurrentServerIndex = 0;
      leftLastServerIndex = 0;
      rightLastServerIndex = 0;
      leftInitialServerIndex = 0;
      rightInitialServerIndex = 0;
      leftHasServed = false;
      rightHasServed = false;
      scoreHistory.clear();
    });
  }

  void giveServeToLeft() {
    servingSide = ServeSide.left;
    if (!leftHasServed) {
      leftCurrentServerIndex = leftInitialServerIndex;
      leftLastServerIndex = leftCurrentServerIndex;
      leftHasServed = true;
      return;
    }
    leftCurrentServerIndex = 1 - leftLastServerIndex;
    leftLastServerIndex = leftCurrentServerIndex;
  }

  void giveServeToRight() {
    servingSide = ServeSide.right;
    if (!rightHasServed) {
      rightCurrentServerIndex = rightInitialServerIndex;
      rightLastServerIndex = rightCurrentServerIndex;
      rightHasServed = true;
      return;
    }
    rightCurrentServerIndex = 1 - rightLastServerIndex;
    rightLastServerIndex = rightCurrentServerIndex;
  }

  void addScoreA() {
    if (isGameFinished()) return;
    setState(() {
      pushScoreSnapshot();
      scoreA++;
      if (servingSide == ServeSide.left) {
        leftLastServerIndex = leftCurrentServerIndex;
        leftHasServed = true;
      } else {
        giveServeToLeft();
      }
    });
    _speak(_buildScoreAnnouncement());
  }

  void addScoreB() {
    if (isGameFinished()) return;
    setState(() {
      pushScoreSnapshot();
      scoreB++;
      if (servingSide == ServeSide.right) {
        rightLastServerIndex = rightCurrentServerIndex;
        rightHasServed = true;
      } else {
        giveServeToRight();
      }
    });
    _speak(_buildScoreAnnouncement());
  }

  void loseRallyByServingTeam() {
    if (isGameFinished()) return;
    setState(() {
      pushScoreSnapshot();
      if (servingSide == ServeSide.left) {
        giveServeToRight();
      } else {
        giveServeToLeft();
      }
    });
  }

  void changeCourt() {
    setState(() {
      pushScoreSnapshot();
      final tempL1 = leftPlayer1;
      final tempL2 = leftPlayer2;
      leftPlayer1 = rightPlayer1;
      leftPlayer2 = rightPlayer2;
      rightPlayer1 = tempL1;
      rightPlayer2 = tempL2;

      final tempScore = scoreA;
      scoreA = scoreB;
      scoreB = tempScore;

      final tempCurrent = leftCurrentServerIndex;
      leftCurrentServerIndex = rightCurrentServerIndex;
      rightCurrentServerIndex = tempCurrent;

      final tempLast = leftLastServerIndex;
      leftLastServerIndex = rightLastServerIndex;
      rightLastServerIndex = tempLast;

      final tempInitial = leftInitialServerIndex;
      leftInitialServerIndex = rightInitialServerIndex;
      rightInitialServerIndex = tempInitial;

      final tempHasServed = leftHasServed;
      leftHasServed = rightHasServed;
      rightHasServed = tempHasServed;

      servingSide = servingSide == ServeSide.left
          ? ServeSide.right
          : ServeSide.left;
    });
  }

  void applyServeSetup(ScoreboardServeSetupResult result) {
    final firstIsLeft = isLeftTeamGlobalIndex(result.firstServerGlobalIndex);
    final leftInitial = firstIsLeft
        ? toLocalIndex(result.firstServerGlobalIndex)
        : toLocalIndex(result.opponentFirstServerGlobalIndex);
    final rightInitial = firstIsLeft
        ? toLocalIndex(result.opponentFirstServerGlobalIndex)
        : toLocalIndex(result.firstServerGlobalIndex);
    setState(() {
      leftInitialServerIndex = leftInitial;
      rightInitialServerIndex = rightInitial;
      leftCurrentServerIndex = leftInitialServerIndex;
      rightCurrentServerIndex = rightInitialServerIndex;
      leftLastServerIndex = leftInitialServerIndex;
      rightLastServerIndex = rightInitialServerIndex;
      servingSide = firstIsLeft ? ServeSide.left : ServeSide.right;
      leftHasServed = firstIsLeft;
      rightHasServed = !firstIsLeft;
    });
  }

  Future<void> openBulkPlayerEditPage() async {
    final result = await Navigator.push<ScoreboardBulkPlayerEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreboardBulkPlayerEditPage(
          leftPlayer1: leftPlayer1,
          leftPlayer2: leftPlayer2,
          rightPlayer1: rightPlayer1,
          rightPlayer2: rightPlayer2,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      leftPlayer1 = result.leftPlayer1.trim().isEmpty
          ? '선수1'
          : result.leftPlayer1.trim();
      leftPlayer2 = result.leftPlayer2.trim().isEmpty
          ? '선수2'
          : result.leftPlayer2.trim();
      rightPlayer1 = result.rightPlayer1.trim().isEmpty
          ? '선수3'
          : result.rightPlayer1.trim();
      rightPlayer2 = result.rightPlayer2.trim().isEmpty
          ? '선수4'
          : result.rightPlayer2.trim();
    });
  }
}

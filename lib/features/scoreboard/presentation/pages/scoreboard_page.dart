import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ← 이 줄 추가

import 'package:funminton_club_app/features/scoreboard/domain/enums/serve_side.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_result_models.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/pages/scoreboard_state.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/widgets/scoreboard_common_buttons.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/widgets/scoreboard_player_header_widget.dart';
import 'package:funminton_club_app/features/scoreboard/presentation/widgets/scoreboard_score_board_widget.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  // ignore: no_logic_in_create_state
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends ScoreboardStateBase<ScoreboardPage> {
  // ★ 자체 TTS 완전 제거! 부모 클래스(ScoreboardStateBase)의
  //   _tts, _ttsEnabled, toggleTts(), _speak(), _announceScore()만 사용
  //   → 중복 TTS 제거, 스피커 on/off 완전 작동

  // ── 전체화면 ──────────────────────────────────────────────────
  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1D4ED8),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFEFF2F7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initTts(); // 부모의 TTS 초기화
      await _initUndoTts(); // ★ 추가: 점수취소 전용 TTS 초기화
      _enterFullscreen();
      if (mounted) loadSavedMatches();
    });
  }

  @override
  void dispose() {
    _undoTts.stop(); // ★ 추가
    _exitFullscreen();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    disposeScoreboard();
    super.dispose();
  }

  // ── 점수취소용 독립 TTS ────────────────────────────────────────
  //  부모의 _tts가 private이라 공유 불가 → 전용 TTS 객체 따로 생성
  //  (부모의 ttsEnabled 상태는 공유하므로 스피커 꺼짐 상태도 정확히 반영)
  final FlutterTts _undoTts = FlutterTts();
  bool _undoTtsReady = false;

  Future<void> _initUndoTts() async {
    try {
      await _undoTts.setLanguage('ko-KR');
      await _undoTts.setSpeechRate(0.9);
      await _undoTts.setVolume(1.0);
      await _undoTts.setPitch(1.0);
      _undoTtsReady = true;
    } catch (_) {
      _undoTtsReady = false;
    }
  }

  // ── 점수취소 (음성 안내 포함) ──────────────────────────────────
  Future<void> _handleUndo() async {
    undoLastScore();
    // ★ 부모의 ttsEnabled 상태를 확인 (스피커 꺼져 있으면 소리 안 남)
    if (!ttsEnabled) return;
    if (!_undoTtsReady) return;
    try {
      await _undoTts.stop();
      await _undoTts.speak('점수 취소');
    } catch (_) {}
  }

  // ── 저장 다이얼로그 ────────────────────────────────────────────
  Future<void> _onSaveTapped() async {
    if (!saveEnabled) {
      final msg = !canSaveMatch
          ? '선수명을 2명 이상 입력해야 저장할 수 있습니다'
          : '점수가 10점을 넘어야 기록저장할 수 있습니다';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
      );
      return;
    }
    final myTeamSide = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: SizedBox(
            width: size.width * 0.5,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.75),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나의 팀 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '승/패 기준이 될 나의 팀을 선택하세요.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _myTeamOption(
                      ctx: ctx,
                      side: 'left',
                      label: '$leftPlayer1 / $leftPlayer2',
                      score: scoreA,
                      isWin: scoreA > scoreB,
                    ),
                    const SizedBox(height: 7),
                    _myTeamOption(
                      ctx: ctx,
                      side: 'right',
                      label: '$rightPlayer1 / $rightPlayer2',
                      score: scoreB,
                      isWin: scoreB > scoreA,
                    ),
                    const SizedBox(height: 7),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'none'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 34),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        '선택 안 함',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 30),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || myTeamSide == null) return;
    await saveCurrentMatch(myTeamSide);
  }

  Widget _myTeamOption({
    required BuildContext ctx,
    required String side,
    required String label,
    required int score,
    required bool isWin,
  }) {
    final bg = isWin
        ? const Color(0xFF1565C0).withValues(alpha: 0.08)
        : const Color(0xFFD32F2F).withValues(alpha: 0.08);
    final border = isWin ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
    final resultText = isWin
        ? '승'
        : (score < (side == 'left' ? scoreB : scoreA) ? '패' : '무');
    final resultColor = isWin
        ? const Color(0xFF1565C0)
        : (resultText == '패' ? const Color(0xFFD32F2F) : Colors.grey);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.pop(ctx, side),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$score점',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                resultText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: resultColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 바텀시트 ───────────────────────────────────────────────────
  Future<T?> _showResponsiveBottomSheet<T>({
    required Widget child,
    double maxWidthFactor = 0.72,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (sheetCtx) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final maxH = constraints.maxHeight * 0.9;
            final maxW = constraints.maxWidth * maxWidthFactor;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxW,
                      maxHeight: maxH,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openServeSetupSheet() async {
    int? tempFirst;
    int? tempOpponent;
    if (leftHasServed || rightHasServed) {
      tempFirst = servingSide == ServeSide.left
          ? leftCurrentServerIndex
          : rightCurrentServerIndex + 2;
      tempOpponent = servingSide == ServeSide.left
          ? rightInitialServerIndex + 2
          : leftInitialServerIndex;
    }
    final result = await _showResponsiveBottomSheet<ScoreboardServeSetupResult>(
      maxWidthFactor: 0.72,
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          final opponents = tempFirst == null
              ? <int>[]
              : opponentCandidatesOf(tempFirst!);
          final opponentValid =
              tempOpponent != null && opponents.contains(tempOpponent);
          final canConfirm = tempFirst != null && opponentValid;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '첫 서브 선수',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _buildServeSelectionRow(
                selectedGlobalIndex: tempFirst,
                selectableIndexes: const [0, 1, 2, 3],
                onSelect: (i) => setLocal(() {
                  tempFirst = i;
                  tempOpponent = null;
                }),
              ),
              const SizedBox(height: 16),
              const Text(
                '상대편 첫 서브 선수',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _buildServeSelectionRow(
                selectedGlobalIndex: tempOpponent,
                selectableIndexes: opponents,
                onSelect: (i) => setLocal(() => tempOpponent = i),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('닫기'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.pop(
                            ctx,
                            ScoreboardServeSetupResult(
                              firstServerGlobalIndex: tempFirst!,
                              opponentFirstServerGlobalIndex: tempOpponent!,
                            ),
                          )
                        : null,
                    child: const Text('확인'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    applyServeSetup(result);
  }

  Future<void> _openTargetScoreSheet() async {
    int tempTarget = targetScore;
    bool tempUseDeuce = useDeuce;
    final result = await _showResponsiveBottomSheet<Map<String, dynamic>>(
      maxWidthFactor: 0.55,
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '목표 점수 / 듀스 설정',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ScoreOptionButton(
                      label: '21점',
                      selected: tempTarget == 21,
                      onTap: () => setLocal(() => tempTarget = 21),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScoreOptionButton(
                      label: '25점',
                      selected: tempTarget == 25,
                      onTap: () => setLocal(() => tempTarget = 25),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '듀스 있음',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '2점 차이 날 때까지 계속 진행',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: tempUseDeuce,
                      onChanged: (v) => setLocal(() => tempUseDeuce = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, {
                      'targetScore': tempTarget,
                      'useDeuce': tempUseDeuce,
                    }),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      targetScore = result['targetScore'] as int;
      useDeuce = result['useDeuce'] as bool;
    });
  }

  // ── 다이얼로그 ─────────────────────────────────────────────────
  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('점수리셋'),
        content: const Text('점수를 리셋하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              resetScores();
              Navigator.pop(ctx);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showGameEndDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게임종료'),
        content: const Text('게임을 종료하고 앱으로 돌아가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── 서브 선택 행 ───────────────────────────────────────────────
  Widget _buildServeSelectionRow({
    required int? selectedGlobalIndex,
    required List<int> selectableIndexes,
    required ValueChanged<int> onSelect,
  }) {
    Widget box(int index) {
      final selected = selectedGlobalIndex == index;
      final enabled = selectableIndexes.contains(index);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? () => onSelect(index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              decoration: BoxDecoration(
                color: !enabled
                    ? const Color(0xFFE6E6E6)
                    : selected
                    ? const Color(0xFF68A0F0)
                    : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? const Color(0xFF3E76C9) : Colors.black12,
                  width: selected ? 1.4 : 1.0,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      allPlayers[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: !enabled
                            ? Colors.black38
                            : selected
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        box(0),
        box(1),
        const SizedBox(
          width: 26,
          child: Center(
            child: Text(
              'vs',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
        ),
        box(2),
        box(3),
      ],
    );
  }

  // ── 팀 컬럼 ────────────────────────────────────────────────────
  Widget _buildTeamColumn({
    required String player1,
    required String player2,
    required bool player1Serving,
    required bool player2Serving,
    required int score,
    required bool isServingTeam,
    required VoidCallback onScoreTap,
  }) {
    return Column(
      children: [
        ScoreboardPlayerHeaderWidget(
          player1: player1,
          player2: player2,
          player1Serving: player1Serving,
          player2Serving: player2Serving,
          onEditTeam: openBulkPlayerEditPage,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ScoreboardScoreBoardWidget(
            score: score,
            isServingTeam: isServingTeam,
            targetScore: targetScore,
            onTap: onScoreTap,
            onLongPress: loseRallyByServingTeam,
          ),
        ),
      ],
    );
  }

  // ── 스코어 카드 ────────────────────────────────────────────────
  Widget _buildScoreCard() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFFFFF33),
        borderRadius: BorderRadius.circular(16),
        elevation: 12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openTargetScoreSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '스코어',
                      style: TextStyle(
                        color: Color(0xFF4A4300),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$targetScore',
                      style: const TextStyle(
                        color: Color(0xFF3C3600),
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        height: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      deuceLabel,
                      style: const TextStyle(
                        color: Color(0xFF4A4300),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CHANGE 버튼 ────────────────────────────────────────────────
  Widget _buildCourtChangeButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cw = constraints.maxWidth;
        final double iconSize = (cw * 0.18).clamp(12.0, 22.0);
        final double lineW = (cw * 0.35).clamp(24.0, 44.0);

        return SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: changeCourt, // 부모 함수가 이미 "코트 체인지" 음성 안내 포함
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F3460).withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            color: const Color(0xFF4FC3F7),
                            size: iconSize,
                          ),
                          SizedBox(width: cw * 0.03),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: lineW,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4FC3F7),
                                      Color(0xFF81D4FA),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: lineW,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF81D4FA),
                                      Color(0xFF4FC3F7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: cw * 0.03),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF4FC3F7),
                            size: iconSize,
                          ),
                        ],
                      ),
                      SizedBox(height: cw * 0.04),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CHANGE',
                          style: TextStyle(
                            color: const Color(0xFF4FC3F7),
                            fontSize: (cw * 0.11).clamp(9.0, 14.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 가운데 컬럼 ────────────────────────────────────────────────
  Widget _buildCenterColumn() {
    return Column(
      children: [
        Expanded(flex: 4, child: _buildScoreCard()),
        const SizedBox(height: 4),
        Expanded(flex: 3, child: _buildCourtChangeButton()),
        const SizedBox(height: 4),
        CenterFixedButton(
          text: '점수취소',
          backgroundColor: const Color.fromARGB(255, 81, 136, 255),
          borderColor: Colors.transparent,
          textColor: Colors.black,
          onTap: _handleUndo, // ★ 점수취소 + 음성
        ),
      ],
    );
  }

  // ── TTS 버튼 (부모의 toggleTts 사용!) ─────────────────────────
  Widget _buildTtsButton({required double size, double? iconSize}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          toggleTts(); // ★ 부모의 공식 toggle 함수 사용 (TTS 정지까지 포함)
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // ★ 부모의 ttsEnabled 사용
            color: ttsEnabled ? const Color(0xFFFFD700) : Colors.white24,
            width: 1.4,
          ),
        ),
        child: Icon(
          ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: ttsEnabled ? const Color(0xFFFFD700) : Colors.white38,
          size: iconSize ?? (size * 0.5).clamp(14.0, 24.0),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── 가로 화면: 실제 점수판 ────────────────────────────────────
  // ══════════════════════════════════════════════════════════════
  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    final double sw = constraints.maxWidth;
    final double sh = constraints.maxHeight;

    final double hPad = sw * 0.004;
    final double centerWidth = (sw * 0.13).clamp(80.0, 120.0);
    final double centerGap = (sw * 0.012).clamp(6.0, 16.0);
    final double scoreGap = (sh * 0.015).clamp(4.0, 10.0);
    final double bottomRowH = (sh * 0.12).clamp(32.0, 50.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 2),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamColumn(
                    player1: leftPlayer1,
                    player2: leftPlayer2,
                    player1Serving: isLeftPlayer1Serving,
                    player2Serving: isLeftPlayer2Serving,
                    score: scoreA,
                    isServingTeam: servingSide == ServeSide.left,
                    onScoreTap: addScoreA, // ★ 부모의 addScoreA (이미 음성 포함)
                  ),
                ),
                SizedBox(width: centerGap),
                SizedBox(width: centerWidth, child: _buildCenterColumn()),
                SizedBox(width: centerGap),
                Expanded(
                  child: _buildTeamColumn(
                    player1: rightPlayer1,
                    player2: rightPlayer2,
                    player1Serving: isRightPlayer1Serving,
                    player2Serving: isRightPlayer2Serving,
                    score: scoreB,
                    isServingTeam: servingSide == ServeSide.right,
                    onScoreTap: addScoreB, // ★ 부모의 addScoreB
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: scoreGap),
          SizedBox(
            height: bottomRowH,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTtsButton(size: sw * 0.09),
                      SizedBox(width: sw * 0.008),
                      SizedBox(
                        width: sw * 0.135,
                        child: BottomTextButton(
                          text: '서브선택',
                          textColor: Colors.white,
                          backgroundColor: Colors.black,
                          borderColor: Colors.white,
                          onTap: _openServeSetupSheet,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: sw * 0.135,
                        child: BottomTextButton(
                          text: '점수리셋',
                          textColor: const Color(0xFF00E5FF),
                          backgroundColor: Colors.black,
                          borderColor: Colors.white,
                          onTap: _showResetConfirmDialog,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: centerGap),
                SizedBox(width: centerWidth),
                SizedBox(width: centerGap),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: sw * 0.135,
                        child: BottomTextButton(
                          text: '게임종료',
                          textColor: const Color(0xFFFF79C6),
                          backgroundColor: Colors.black,
                          borderColor: Colors.white,
                          onTap: _showGameEndDialog,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: sw * 0.135,
                        child: BottomTextButton(
                          text: '기록저장',
                          textColor: saveEnabled
                              ? Colors.white
                              : Colors.white38,
                          backgroundColor: Colors.black,
                          borderColor: saveEnabled
                              ? Colors.white
                              : Colors.white24,
                          onTap: saveEnabled ? _onSaveTapped : null,
                          onLongPress: openSavedMatchesPage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── 세로 화면: 가로 회전 안내 ─────────────────────────────────
  // ══════════════════════════════════════════════════════════════
  Widget _buildPortraitLock() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutBack,
              builder: (_, v, child) {
                return Transform.rotate(
                  angle: (1 - v) * 1.5,
                  child: Opacity(opacity: v, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.screen_rotation_rounded,
                  size: 72,
                  color: Color(0xFF4FC3F7),
                ),
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              '휴대폰을 가로로 돌려주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '점수판은 가로 모드에서 가장 잘 보입니다',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
              label: const Text(
                '홈으로 돌아가기',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _enterFullscreen();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          return isLandscape
              ? _buildLandscapeLayout(constraints)
              : _buildPortraitLock();
        },
      ),
    );
  }
}

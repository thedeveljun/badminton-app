import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_saved_match_record.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_result_models.dart';

class ScoreboardSavedMatchesPage extends StatefulWidget {
  final String savedMatchesKey;
  final List<ScoreboardSavedMatchRecord> initialMatches;

  const ScoreboardSavedMatchesPage({
    super.key,
    required this.savedMatchesKey,
    required this.initialMatches,
  });

  @override
  State<ScoreboardSavedMatchesPage> createState() =>
      _ScoreboardSavedMatchesPageState();
}

class _ScoreboardSavedMatchesPageState
    extends State<ScoreboardSavedMatchesPage> {
  late List<ScoreboardSavedMatchRecord> _savedMatches;
  final Set<int> _selectedIndexes = {};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _savedMatches = List<ScoreboardSavedMatchRecord>.from(
      widget.initialMatches,
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String _formatSavedAt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _persistMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _savedMatches.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(widget.savedMatchesKey, encoded);
  }

  Future<void> _deleteAllSavedMatches() async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('전체삭제'),
            content: const Text('저장된 기록을 모두 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('확인'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.savedMatchesKey);

    if (!mounted) return;
    setState(() {
      _savedMatches = [];
      _selectedIndexes.clear();
      _changed = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('저장된 기록을 모두 삭제했습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteSelectedSavedMatches() async {
    if (_selectedIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 기록을 선택하세요'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('선택삭제'),
            content: Text('선택한 ${_selectedIndexes.length}개 기록을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('확인'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    setState(() {
      _savedMatches = [
        for (int i = 0; i < _savedMatches.length; i++)
          if (!_selectedIndexes.contains(i)) _savedMatches[i],
      ];
      _selectedIndexes.clear();
      _changed = true;
    });

    await _persistMatches();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('선택한 기록을 삭제했습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _closePage() {
    Navigator.pop(
      context,
      ScoreboardSavedMatchesPageResult(
        savedMatches: _savedMatches,
        changed: _changed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _savedMatches.isNotEmpty &&
        _selectedIndexes.length == _savedMatches.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closePage();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.4,
          centerTitle: false,
          leading: IconButton(
            onPressed: _closePage,
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          titleSpacing: 0,
          title: const Text(
            '최근 저장 기록',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _savedMatches.isEmpty ? null : _deleteAllSavedMatches,
              child: const Text('전체삭제'),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _savedMatches.isEmpty
                          ? null
                          : () {
                              setState(() {
                                if (allSelected) {
                                  _selectedIndexes.clear();
                                } else {
                                  _selectedIndexes
                                    ..clear()
                                    ..addAll(
                                      List.generate(
                                        _savedMatches.length,
                                        (i) => i,
                                      ),
                                    );
                                }
                              });
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(allSelected ? '전체해제' : '전체선택'),
                    ),
                    const SizedBox(width: 2),
                    TextButton(
                      onPressed: _savedMatches.isEmpty
                          ? null
                          : _deleteSelectedSavedMatches,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('선택삭제'),
                    ),
                    const Spacer(),
                    Text(
                      '선택 ${_selectedIndexes.length}개',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _savedMatches.isEmpty
                    ? const Center(
                        child: Text(
                          '저장된 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 5, 12, 8),
                        itemCount: _savedMatches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 3),
                        itemBuilder: (context, index) {
                          final item = _savedMatches[index];
                          final isSelected = _selectedIndexes.contains(index);

                          final String myTeam = item.myTeamSide;
                          final int myScore = myTeam == 'left'
                              ? item.scoreA
                              : myTeam == 'right'
                              ? item.scoreB
                              : -1;
                          final int oppScore = myTeam == 'left'
                              ? item.scoreB
                              : myTeam == 'right'
                              ? item.scoreA
                              : -1;

                          final String resultText;
                          final Color resultColor;
                          if (myTeam == 'none') {
                            resultText = '-';
                            resultColor = Colors.grey;
                          } else if (myScore > oppScore) {
                            resultText = '승';
                            resultColor = const Color(0xFF1565C0);
                          } else if (myScore < oppScore) {
                            resultText = '패';
                            resultColor = const Color(0xFFD32F2F);
                          } else {
                            resultText = '무';
                            resultColor = Colors.grey;
                          }

                          final String myTeamLabel = myTeam == 'left'
                              ? '${item.leftPlayer1}/${item.leftPlayer2}'
                              : myTeam == 'right'
                              ? '${item.rightPlayer1}/${item.rightPlayer2}'
                              : '';

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndexes.remove(index);
                                } else {
                                  _selectedIndexes.add(index);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEAF3FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF68A0F0)
                                      : const Color(0xFFE4E7EB),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Checkbox(
                                      value: isSelected,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedIndexes.add(index);
                                          } else {
                                            _selectedIndexes.remove(index);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item.leftPlayer1}/${item.leftPlayer2}  vs  ${item.rightPlayer1}/${item.rightPlayer2}',
                                                style: const TextStyle(
                                                  fontSize: 13, // ★ 12 → 13
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (myTeam != 'none') ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: resultColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  resultText,
                                                  style: TextStyle(
                                                    fontSize: 12, // ★ 11 → 12
                                                    fontWeight: FontWeight.w700,
                                                    color: resultColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (myTeamLabel.isNotEmpty)
                                              Text(
                                                '$myTeamLabel  ',
                                                style: TextStyle(
                                                  fontSize: 12, // ★ 11 → 12
                                                  fontWeight: FontWeight.w600,
                                                  color: resultColor,
                                                ),
                                              ),
                                            Text(
                                              '${item.scoreA} : ${item.scoreB}',
                                              style: const TextStyle(
                                                fontSize: 13, // ★ 12 → 13
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatSavedAt(item.savedAt),
                                          style: const TextStyle(
                                            fontSize: 11.5, // ★ 10.5 → 11.5
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

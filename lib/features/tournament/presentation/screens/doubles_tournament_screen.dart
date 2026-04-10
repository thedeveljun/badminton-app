import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';
import '../../../members/utils/member_storage.dart';
import 'tournament_models.dart';
import 'tournament_bracket_widgets.dart';
import 'tournament_setting_widgets.dart';

class DoublesTournamentScreen extends StatefulWidget {
  const DoublesTournamentScreen({super.key});

  @override
  State<DoublesTournamentScreen> createState() =>
      _DoublesTournamentScreenState();
}

class _DoublesTournamentScreenState extends State<DoublesTournamentScreen> {
  List<MemberItem> _allMembers = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _generated = false;
  List<TournamentMatch> _matches = [];
  int _tabIndex = 0;

  final Set<RoundType> _selectedRounds = {
    RoundType.same,
    RoundType.balanced,
    RoundType.random,
  };
  int _courtCount = 3;
  int _gamesPerPlayer = 3;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final saved = await MemberStorage.loadMembers();
    setState(() {
      _allMembers = saved ?? [];
      _courtCount = _recCourts(_allMembers.length);
      _isLoading = false;
    });
  }

  int _recCourts(int n) => (n / 4).floor().clamp(1, 10);

  List<RoundType> get _orderedRounds =>
      RoundType.values.where((r) => _selectedRounds.contains(r)).toList();

  Map<String, List<MemberItem>> get _grouped {
    final g = <String, List<MemberItem>>{};
    for (final m in _allMembers) {
      g.putIfAbsent(m.grade, () => []).add(m);
    }
    return g;
  }

  bool get _canGen => _selectedIds.length >= 4 && _selectedRounds.isNotEmpty;

  void _generate() {
    if (_selectedIds.length < 4) {
      _snack('최소 4명 이상 선택해야 합니다.');
      return;
    }
    if (_selectedRounds.isEmpty) {
      _snack('라운드 유형을 1개 이상 선택하세요.');
      return;
    }
    final selected = _allMembers
        .where((m) => _selectedIds.contains(m.id))
        .toList();
    setState(() {
      _matches = TournamentEngine(
        selected,
        _orderedRounds,
        _courtCount,
        _gamesPerPlayer,
      ).generate();
      _generated = true;
      _tabIndex = 2;
    });
  }

  void _reshuffle() {
    final selected = _allMembers
        .where((m) => _selectedIds.contains(m.id))
        .toList();
    setState(() {
      _matches = TournamentEngine(
        selected,
        _orderedRounds,
        _courtCount,
        _gamesPerPlayer,
      ).generate();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        surfaceTintColor: const Color(0xFFF6F7FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 34,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF111111),
          ),
        ),
        title: const Text(
          '복식 대진표',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          if (_generated)
            TextButton.icon(
              onPressed: _reshuffle,
              icon: const Icon(
                Icons.shuffle_rounded,
                size: 18,
                color: Color(0xFF5B8ABB),
              ),
              label: const Text(
                '다시섞기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B8ABB),
                ),
              ),
            ),
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: Color(0xFF5B8ABB),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E4EC), width: 1),
              ),
            ),
            child: Row(
              children: [
                TournamentTabBtn(
                  label: '참가자',
                  badge: '${_selectedIds.length}명',
                  selected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                TournamentTabBtn(
                  label: '설정',
                  badge: '$_courtCount코트 · ${_gamesPerPlayer}게임',
                  selected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                TournamentTabBtn(
                  label: '대진표',
                  badge: _generated ? '${_matches.length}경기' : '',
                  selected: _tabIndex == 2,
                  onTap: () {
                    if (!_generated) {
                      _snack('대진표를 먼저 생성하세요.');
                      return;
                    }
                    setState(() => _tabIndex = 2);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [_buildSelectTab(), _buildSettingTab(), _buildBracketTab()],
      ),
      bottomNavigationBar: _tabIndex != 2
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canGen ? _generate : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF5B8ABB),
                      disabledBackgroundColor: const Color(0xFFCDD5DF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      !_canGen
                          ? (_selectedIds.length < 4
                                ? '4명 이상 선택하세요  (현재 ${_selectedIds.length}명)'
                                : '라운드 유형을 1개 이상 선택하세요')
                          : '대진표 생성  (${_selectedIds.length}명 · ${_courtCount}코트 · 1인 ${_gamesPerPlayer}게임)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ── 탭1: 참가자 선택 ──────────────────────────────────────────
  Widget _buildSelectTab() {
    if (_allMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 12),
            const Text(
              '회원관리에서 회원을 먼저 등록해주세요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('다시 불러오기'),
            ),
          ],
        ),
      );
    }

    final grouped = _grouped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        GradeSummaryBar(grouped: grouped, selectedIds: _selectedIds),
        const SizedBox(height: 8),
        if (_selectedIds.isNotEmpty) ...[
          CourtRecommendBanner(
            selected: _selectedIds.length,
            courtCount: _courtCount,
            onGoSetting: () => setState(() => _tabIndex = 1),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            TournamentPill(
              text: _selectedIds.length == _allMembers.length ? '전체해제' : '전체선택',
              enabled: true,
              onTap: () => setState(() {
                if (_selectedIds.length == _allMembers.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(_allMembers.map((m) => m.id));
                }
                _courtCount = _recCourts(_selectedIds.length);
              }),
            ),
            const SizedBox(width: 6),
            TournamentPill(
              text: '선택초기화',
              enabled: _selectedIds.isNotEmpty,
              onTap: () => setState(() {
                _selectedIds.clear();
                _courtCount = _recCourts(0);
              }),
            ),
            const Spacer(),
            SelectionCountBadge(count: _selectedIds.length),
          ],
        ),
        const SizedBox(height: 10),
        for (final grade in ['A', 'B', 'C', 'D', '초심'])
          if (grouped.containsKey(grade)) ...[
            GradeSectionHeader(
              grade: grade,
              total: grouped[grade]!.length,
              selected: grouped[grade]!
                  .where((m) => _selectedIds.contains(m.id))
                  .length,
            ),
            const SizedBox(height: 5),
            ...(List<MemberItem>.from(
              grouped[grade]!,
            )..sort((a, b) => tournamentAge(a) - tournamentAge(b))).map(
              (m) => MemberCheckRow(
                member: m,
                checked: _selectedIds.contains(m.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedIds.add(m.id);
                  } else {
                    _selectedIds.remove(m.id);
                  }
                  _courtCount = _recCourts(_selectedIds.length);
                }),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  // ── 탭2: 설정 ────────────────────────────────────────────────
  Widget _buildSettingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        SettingSection(
          title: '사용 코트 수',
          icon: Icons.grid_view_rounded,
          child: CourtSelector(
            value: _courtCount,
            selectedCount: _selectedIds.length,
            onChanged: (v) => setState(() => _courtCount = v),
          ),
        ),
        const SizedBox(height: 16),
        SettingSection(
          title: '1인당 경기 수',
          icon: Icons.sports_tennis_rounded,
          child: GamesPerPlayerSelector(
            value: _gamesPerPlayer,
            onChanged: (v) => setState(() => _gamesPerPlayer = v),
          ),
        ),
        const SizedBox(height: 16),
        SettingSection(
          title: '라운드 유형',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB8D0EC)),
                ),
                child: const Text(
                  '선택한 유형이 순서대로 반복됩니다.\n예) 동일+랜덤 선택 → 동일→랜덤→동일→랜덤 순으로 게임 구성',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final type in RoundType.values)
                RoundOptionCard(
                  type: type,
                  selected: _selectedRounds.contains(type),
                  onToggle: () => setState(() {
                    if (_selectedRounds.contains(type)) {
                      _selectedRounds.remove(type);
                    } else {
                      _selectedRounds.add(type);
                    }
                  }),
                ),
            ],
          ),
        ),
        if (_selectedRounds.isNotEmpty && _gamesPerPlayer > 0) ...[
          const SizedBox(height: 16),
          SettingSection(
            title: '구성 미리보기',
            icon: Icons.preview_rounded,
            child: Column(
              children: List.generate(_gamesPerPlayer, (i) {
                final rt = _orderedRounds[i % _orderedRounds.length];
                return RoundPreviewRow(roundNum: i + 1, type: rt);
              }),
            ),
          ),
        ],
      ],
    );
  }

  // ── 탭3: 대진표 ──────────────────────────────────────────────
  Widget _buildBracketTab() {
    if (_matches.isEmpty) {
      return const Center(
        child: Text(
          '대진표가 없습니다.',
          style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
        ),
      );
    }

    final byeCount = _matches
        .where((m) => m.teamA.isBye || m.teamB.isBye)
        .length;
    final byCourt = <int, List<TournamentMatch>>{};
    for (final m in _matches) {
      byCourt.putIfAbsent(m.courtNo, () => []).add(m);
    }
    final sortedCourts = byCourt.keys.toList()..sort();

    return Column(
      children: [
        // 상단 요약 배너 — 재정관리 헤더와 동일한 네이비
        Container(
          width: double.infinity,
          color: const Color(0xFF0A245C),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _summaryChip(
                '참가',
                '${_selectedIds.length}명',
                const Color(0xFF5B8ABB),
              ),
              const SizedBox(width: 6),
              _summaryChip('코트', '$_courtCount코트', const Color(0xFF4A7FB5)),
              const SizedBox(width: 6),
              _summaryChip(
                '경기',
                '${_matches.length}게임',
                const Color(0xFF3A6FA5),
              ),
              if (byeCount > 0) ...[
                const SizedBox(width: 6),
                _summaryChip('부전승', '$byeCount', const Color(0xFFC58A00)),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: sortedCourts
                .map(
                  (court) =>
                      CourtSection(courtNo: court, matches: byCourt[court]!),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

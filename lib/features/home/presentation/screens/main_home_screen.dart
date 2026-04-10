// ═══════════════════════════════════════════════════════════════
// main_home_screen.dart  ·  편민턴 메인 홈
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── 화면 import ───────────────────────────────────────────────
import '../../../members/presentation/screens/club_member_screen.dart';
import '../../../members/utils/member_storage.dart';
import '../../../tournament/presentation/screens/doubles_tournament_screen.dart';
import '../../../finance/presentation/screens/club_finance_screen.dart';
import '../../../finance/presentation/screens/finance_models.dart';

// ── 점수판 import (badminton_score_app 통합) ──────────────────
import 'package:funminton_club_app/features/scoreboard/presentation/pages/scoreboard_page.dart';

// ═══════════════════════════════════════════════════════════════
// 색상 · 수치 상수
// ═══════════════════════════════════════════════════════════════
abstract final class _K {
  static const heroTop = Color(0xFF1246C8);
  static const heroBot = Color(0xFF0D3BB0);
  static const lime = Color(0xFFCAFF70);
  static const pageBg = Color(0xFFEEF2FF);

  static const cardBg = Colors.white;
  static const cardBord = Color(0xFFE0E8FF);

  static const mBg = Color(0xFFDCFCE7);
  static const mTx = Color(0xFF16A34A);
  static const fBg = Color(0xFFDBEAFE);
  static const fTx = Color(0xFF1D4ED8);
  static const tBg = Color(0xFFFEF3C7);
  static const tTx = Color(0xFFB45309);
  static const sBg = Color(0xFFEDE9FE);
  static const sTx = Color(0xFF6D28D9);

  static const eBg = Color(0xFFDCFCE7);
  static const eBd = Color(0xFF86EFAC);
  static const eTx = Color(0xFF16A34A);
  static const eBot = Color(0xFFBBF7D0);
  static const eBotBd = Color(0xFFDCFCE7);

  static const statBg = Color(0xFF061E5C);
  static const statDiv = Color(0x1AFFFFFF);
}

// ═══════════════════════════════════════════════════════════════
// 데이터 모델
// ═══════════════════════════════════════════════════════════════
class _Stat {
  final String number, label;
  const _Stat(this.number, this.label);
}

class _Menu {
  final String title, desc;
  final IconData icon;
  final Color bg, tx;
  final VoidCallback onTap;
  const _Menu(this.title, this.desc, this.icon, this.bg, this.tx, this.onTap);
}

// ═══════════════════════════════════════════════════════════════
// MainHomeScreen
// ═══════════════════════════════════════════════════════════════
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _totalMembers = 0;
  int _newMembers = 0;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ── 데이터 로드 ───────────────────────────────────────────────
  Future<void> _loadStats() async {
    final members = await MemberStorage.loadMembers() ?? [];
    final transactions = await FinanceStorage.loadTx();

    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final newCount = members
        .where((m) => m.joinDate.startsWith(thisMonth))
        .length;

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (int s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (int s, t) => s + t.amount);

    setState(() {
      _totalMembers = members.length;
      _newMembers = newCount;
      _balance = income - expense;
    });
  }

  // ── 숫자 포맷 ─────────────────────────────────────────────────
  String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : '$buf';
  }

  // ── 점수판 이동 ──────────────────────────────────────────────
  Future<void> _goToScoreboard(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const ScoreboardPage()),
    );
    // 점수판 dispose에서 방향 복원하므로 여기선 추가 호출 불필요
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _K.pageBg,
      body: Column(
        children: [
          const _HeroBanner(),
          _StatBar(
            stats: [
              _Stat('$_totalMembers명', '회원수'),
              _Stat('$_newMembers명', '신규회원'),
              _Stat(_fmt(_balance), '현재잔액'),
            ],
            onRefresh: _loadStats,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 3, 14, 24),
              child: Column(
                children: [
                  _buildGrid(context),
                  const SizedBox(height: 8),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _EventCard(onTap: () => _snack(context, '이벤트')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final items = <_Menu>[
      _Menu(
        '회원관리',
        '등록 · 조회',
        Icons.people_alt_rounded,
        _K.mBg,
        _K.mTx,
        () async {
          await _go(context, const ClubMemberScreen());
          _loadStats();
        },
      ),
      _Menu(
        '재정관리',
        '회비 · 납부',
        Icons.credit_card_rounded,
        _K.fBg,
        _K.fTx,
        () async {
          await _go(context, const ClubFinanceScreen());
          _loadStats();
        },
      ),
      _Menu(
        '대진표',
        '자유 · 토너먼트',
        Icons.grid_view_rounded,
        _K.tBg,
        _K.tTx,
        () => _go(context, const DoublesTournamentScreen()),
      ),
      // ★ 점수판 — 실제 ScoreboardPage 로 연결
      _Menu(
        '점수판',
        '자유게임 · 기록',
        Icons.scoreboard_rounded,
        _K.sBg,
        _K.sTx,
        () => _goToScoreboard(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (_, i) => _MenuCard(menu: items[i]),
    );
  }

  Future<void> _go(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));

  void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

// ═══════════════════════════════════════════════════════════════
// ① 히어로 배너
// ═══════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: _K.heroTop,
      padding: EdgeInsets.fromLTRB(18, top + 12, 18, 18),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _Circle(170, Colors.white.withOpacity(.07)),
          ),
          Positioned(
            bottom: -20,
            right: 50,
            child: _Circle(90, Colors.white.withOpacity(.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      size: 20,
                      color: _K.heroTop,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    '편민턴',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(.3)),
                    ),
                    child: const Text(
                      '클럽 플랫폼',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                '운동은 즐겁게\n클럽운영은 스마트하게',
                style: TextStyle(
                  color: _K.lime,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '회원관리 · 재정관리 · 대진표 한 번에',
                style: TextStyle(
                  color: Colors.white.withOpacity(.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ═══════════════════════════════════════════════════════════════
// ② 통계바
// ═══════════════════════════════════════════════════════════════
class _StatBar extends StatelessWidget {
  final List<_Stat> stats;
  final VoidCallback? onRefresh;
  const _StatBar({required this.stats, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onRefresh,
      child: Container(
        color: _K.statBg,
        child: Row(
          children: List.generate(stats.length, (i) {
            final isLast = i == stats.length - 1;
            final flex = i == 2 ? 14 : 8;
            return Expanded(
              flex: flex,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          right: BorderSide(color: _K.statDiv, width: 1),
                        ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stats[i].number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stats[i].label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 메뉴 카드
// ═══════════════════════════════════════════════════════════════
class _MenuCard extends StatelessWidget {
  final _Menu menu;
  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _K.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: menu.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: _K.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _K.cardBord),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1246C8).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 아이콘
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: menu.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(menu.icon, size: 19, color: menu.tx),
              ),
              // 텍스트
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    menu.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: menu.tx,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 이벤트 카드
// ═══════════════════════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EventCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _K.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _K.cardBord),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _K.eBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        size: 22,
                        color: _K.eTx,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이벤트',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '행사 · 대회 · 공지 관리',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFD1D5DB),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: const BoxDecoration(
                  color: _K.eBot,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: _K.eBotBd)),
                ),
                child: Wrap(
                  spacing: 6,
                  children: ['일정', '공지', '참가 신청'].map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _K.eBd),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

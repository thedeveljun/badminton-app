// ═══════════════════════════════════════════════════════════════
// main_home_screen.dart  ·  편민턴 메인 홈 (Design A)
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── 화면 import (경로는 프로젝트에 맞게 유지) ──────────────────
import '../../../members/presentation/screens/club_member_screen.dart';
import '../../../tournament/presentation/screens/doubles_tournament_screen.dart';
import '../../../finance/presentation/screens/club_finance_screen.dart';

// ═══════════════════════════════════════════════════════════════
// 색상 · 수치 상수  ·  수정은 여기서만
// ═══════════════════════════════════════════════════════════════
abstract final class _K {
  // 배너
  static const heroTop = Color(0xFF1246C8);
  static const heroBot = Color(0xFF0D3BB0);
  static const lime = Color(0xFFCAFF70);
  static const pageBg = Color(0xFFEEF2FF);

  // 카드 공통
  static const cardBg = Colors.white;
  static const cardBord = Color(0xFFE0E8FF);

  // 메뉴 카드 색상 (배경 · 강조 텍스트)
  static const mBg = Color(0xFFDCFCE7);
  static const mTx = Color(0xFF16A34A);
  static const fBg = Color(0xFFDBEAFE);
  static const fTx = Color(0xFF1D4ED8);
  static const tBg = Color(0xFFFEF3C7);
  static const tTx = Color(0xFFB45309);
  static const sBg = Color(0xFFEDE9FE);
  static const sTx = Color(0xFF6D28D9);

  // 이벤트
  static const eBg = Color(0xFFDCFCE7);
  static const eBd = Color(0xFF86EFAC); // 태그 테두리
  static const eTx = Color.fromARGB(255, 10, 111, 25);
  static const eBot = Color.fromARGB(255, 159, 225, 165); // 하단 바 배경
  static const eBotBd = Color(0xFFDCFCE7); // 하단 바 구분선

  // 통계바
  static const statBg = Color.fromARGB(255, 9, 27, 137);
  static const statDiv = Color(0x1AFFFFFF);
}

// ═══════════════════════════════════════════════════════════════
// 통계 데이터 모델
// ═══════════════════════════════════════════════════════════════
class _Stat {
  final String number, label;
  const _Stat(this.number, this.label);
}

// ═══════════════════════════════════════════════════════════════
// 메뉴 카드 데이터 모델
// ═══════════════════════════════════════════════════════════════
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
class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: _K.pageBg,
      body: Column(
        children: [
          // ① 히어로 배너 (상태바 포함)
          const _HeroBanner(),

          // ② 통계바
          const _StatBar(
            stats: [
              _Stat('128', '회원수'),
              _Stat('12', '신규회원'),
              _Stat('1,250,000', '현재잔액'),
            ],
          ),

          // ③ 메뉴 그리드 + 이벤트 카드 (스크롤)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 3, 14, 24),
              child: Column(
                children: [
                  // 메뉴 그리드 — context 를 직접 넘김
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

  // ── 2×2 메뉴 그리드 빌더 ──────────────────────────────────────
  // ★ 메뉴 추가·삭제 → items 리스트만 수정하세요
  Widget _buildGrid(BuildContext context) {
    final items = <_Menu>[
      _Menu(
        '회원관리',
        '등록 · 조회',
        Icons.people_alt_rounded,
        _K.mBg,
        _K.mTx,
        () => _go(context, const ClubMemberScreen()),
      ),
      _Menu(
        '재정관리',
        '회비 · 납부',
        Icons.credit_card_rounded,
        _K.fBg,
        _K.fTx,
        () => _go(context, const ClubFinanceScreen()),
      ),
      _Menu(
        '대진표',
        '자유 · 토너먼트',
        Icons.grid_view_rounded,
        _K.tBg,
        _K.tTx,
        () => _go(context, const DoublesTournamentScreen()),
      ),
      _Menu(
        '점수판',
        '자유게임 · 기록',
        Icons.scoreboard_rounded,
        _K.sBg,
        _K.sTx,
        () => _snack(context, '점수판은 다음 단계에서 연결합니다.'),
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
        childAspectRatio: 1.28, // 높이 20% 축소 (1.0 → 1.28)
      ),
      itemBuilder: (_, i) => _MenuCard(menu: items[i]),
    );
  }

  // 화면 이동
  void _go(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));

  // 스낵바
  void _snack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

// ═══════════════════════════════════════════════════════════════
// ① 히어로 배너
//   · 슬로건 아래 여백 최소화 (수정 ①)
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
          // 배경 장식 원 ①
          Positioned(
            top: -40,
            right: -30,
            child: _Circle(170, Colors.white.withOpacity(.07)),
          ),
          // 배경 장식 원 ②
          Positioned(
            bottom: -20,
            right: 50,
            child: _Circle(90, Colors.white.withOpacity(.05)),
          ),
          // 콘텐츠
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 앱바 행
              Row(
                children: [
                  // 로고 박스
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
                  // 클럽 플랫폼 칩
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
              // 슬로건 (노란 텍스트)
              const Text(
                '운동은 즐겁게\n클럽운영은 스마트하게',
                style: TextStyle(
                  color: _K.lime,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 5),
              // 서브텍스트
              Text(
                '회원관리 · 재정관리 · 대진표 한 번에',
                style: TextStyle(
                  color: Colors.white.withOpacity(.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500, // 🔥 두껍게
                ),
              ),
              // ① 여백 없음 (padding-bottom 18로 충분)
            ],
          ),
        ],
      ),
    );
  }
}

// 배경 장식 원
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
//   · 패딩 줄여 높이 축소 (수정 ②)
// ═══════════════════════════════════════════════════════════════
class _StatBar extends StatelessWidget {
  final List<_Stat> stats;
  const _StatBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _K.statBg,
      child: Row(
        children: List.generate(stats.length, (i) {
          final isLast = i == stats.length - 1;
          // 회원·이번달: flex 0.7 / 현재잔액: flex 1.6
          final flex = i == 2 ? 14 : 8;
          return Expanded(
            flex: flex,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8), // ② 높이 축소
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
                      fontWeight: FontWeight.w700, // 🔥 두껍게
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 메뉴 카드 위젯
//   · 카드 높이 20% 축소 → childAspectRatio 1.28 (MainHomeScreen._buildGrid)
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _K.cardBord),
          ),
          child: Stack(
            children: [
              // 우상단 accent 삼각 장식
              Positioned(
                top: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: menu.bg,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(38),
                      ),
                    ),
                  ),
                ),
              ),
              // 화살표
              Positioned(
                bottom: 9,
                right: 10,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ),
              // 카드 내용
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 박스
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: menu.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(menu.icon, size: 19, color: menu.tx),
                    ),
                    const Spacer(),
                    // 제목
                    Text(
                      menu.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 부제목
                    Text(
                      menu.desc,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: menu.tx,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ④ 이벤트 카드  ·  B안 스타일
//   · 상단: 아이콘 + 제목/부제목 + 화살표
//   · 하단: 초록 배경 태그 바 (일정 · 공지 · 참가 신청)
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
              // ── 상단 행 ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Row(
                  children: [
                    // 아이콘 박스
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
                    // 제목 + 부제목
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이벤트',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '행사 · 대회 · 공지관리',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 53, 152, 68),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 화살표
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFD1D5DB),
                    ),
                  ],
                ),
              ),

              // ── 하단 태그 바 ──────────────────────────────
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
                          color: _K.eTx,
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

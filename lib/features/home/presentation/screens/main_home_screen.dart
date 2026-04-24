import 'package:flutter/material.dart';

import '../../../finance/presentation/screens/club_finance_screen.dart';
import '../../../members/presentation/screens/club_member_screen.dart';
import '../../../events/presentation/event_screen.dart';
import '../../../tournament/presentation/doubles_tournament_screen.dart';
import '../../../scoreboard/presentation/pages/scoreboard_page.dart';
import '../widgets/home_intro_card.dart';
import '../widgets/home_menu_card.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 히어로 + 통계바 (상태바 영역까지 파란색)
                Container(
                  color: const Color(0xFF1D4ED8),
                  child: const SafeArea(bottom: false, child: HomeIntroCard()),
                ),
                const SizedBox(height: 14),
                // 메뉴 그리드 2x2
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 11,
                    mainAxisSpacing: 11,
                    childAspectRatio: 1.05,
                    children: [
                      HomeMenuCard(
                        icon: Icons.groups_rounded,
                        title: '회원관리',
                        subtitle: '등록 · 조회',
                        iconColor: const Color(0xFF22A06B),
                        iconBgColor: const Color(0xFFDDF5E8),
                        subtitleColor: const Color(0xFF22A06B),
                        onTap: () => _go(context, ClubMemberScreen()),
                      ),
                      HomeMenuCard(
                        icon: Icons.credit_card_rounded,
                        title: '재정관리',
                        subtitle: '회비 · 납부',
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFDCEBFF),
                        subtitleColor: const Color(0xFF2563EB),
                        onTap: () => _go(context, const ClubFinanceScreen()),
                      ),
                      HomeMenuCard(
                        icon: Icons.grid_view_rounded,
                        title: '대진표',
                        subtitle: '자유 · 토너먼트',
                        iconColor: const Color(0xFFE07B3C),
                        iconBgColor: const Color(0xFFFFEDD8),
                        subtitleColor: const Color(0xFFE07B3C),
                        onTap: () =>
                            _go(context, const DoublesTournamentScreen()),
                      ),
                      HomeMenuCard(
                        icon: Icons.scoreboard_rounded,
                        title: '점수판',
                        subtitle: '자유게임 · 기록',
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: const Color(0xFFEDE4FF),
                        subtitleColor: const Color(0xFF7C3AED),
                        onTap: () => _go(context, const ScoreboardPage()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                // 이벤트 카드
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  child: _EventCard(onTap: () => _go(context, EventScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EventCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 정보부
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF5E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: Color(0xFF22A06B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이벤트',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '행사 · 대회 · 공지 관리',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF737C8B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF9AA3B2),
                    ),
                  ],
                ),
              ),
              // 하단 액션 칩 영역 (연두색)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFCFFFE0),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: const [
                    _EventChip(label: '일정'),
                    SizedBox(width: 7),
                    _EventChip(label: '공지'),
                    SizedBox(width: 7),
                    _EventChip(label: '참가 신청'),
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

class _EventChip extends StatelessWidget {
  final String label;

  const _EventChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF22A06B), width: 1.1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF22A06B),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

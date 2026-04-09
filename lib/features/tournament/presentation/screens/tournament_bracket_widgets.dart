import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';
import 'tournament_models.dart';

// ============================================================
// 복식 대진표 — 대진표 표시 위젯
// (_CourtSection, _MatchBlock, _TeamBlock, _PlayerLine)
// ============================================================

/// 코트 카드 — 코트 헤더 + 해당 코트 경기 목록
class CourtSection extends StatelessWidget {
  final int courtNo;
  final List<TournamentMatch> matches;
  const CourtSection({super.key, required this.courtNo, required this.matches});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D8E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // 코트 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              color: Color(0xFF5B8ABB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Text('${courtNo}코트',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          // 경기 목록
          ...matches.asMap().entries.map((entry) {
            return Column(children: [
              if (entry.key > 0) const Divider(height: 1, color: Color(0xFFECEFF4)),
              MatchBlock(
                match: entry.value,
                gameNum: entry.key + 1,
                showGameNum: matches.length > 1,
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

/// 경기 블록 — A팀 | VS | B팀 가로 배치
class MatchBlock extends StatelessWidget {
  final TournamentMatch match;
  final int gameNum;
  final bool showGameNum;
  const MatchBlock({
    super.key,
    required this.match,
    required this.gameNum,
    required this.showGameNum,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게임번호 + 라운드 유형 배지
          if (showGameNum)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: match.roundType.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${gameNum}게임  ${match.roundType.label}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: match.roundType.color)),
              ),
            ),

          // A팀 | VS | B팀
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: TeamBlock(team: match.teamA, label: 'A팀')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  Container(width: 1, height: 24, color: const Color(0xFFDDE3EC)),
                  const SizedBox(height: 6),
                  const Text('VS',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFAAAAAA))),
                  const SizedBox(height: 6),
                  Container(width: 1, height: 24, color: const Color(0xFFDDE3EC)),
                ]),
              ),
              Expanded(child: TeamBlock(team: match.teamB, label: 'B팀')),
            ],
          ),
        ],
      ),
    );
  }
}

/// 팀 블록 — 팀 라벨 + 선수 2명
class TeamBlock extends StatelessWidget {
  final TournamentTeam team;
  final String label;
  const TeamBlock({super.key, required this.team, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5B8ABB))),
        ),
        const SizedBox(height: 10),
        PlayerLine(player: team.p1),
        const SizedBox(height: 8),
        PlayerLine(player: team.p2),
      ],
    );
  }
}

/// 선수 한 줄 — 이름(크게) + 성별 + 급수 / 부전승 처리
class PlayerLine extends StatelessWidget {
  final MemberItem? player;
  const PlayerLine({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    if (p == null) {
      return const Text('부전승',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFFBBBBBB),
              fontStyle: FontStyle.italic));
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        TextSpan(text: p.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: Color(0xFF111111), height: 1.2)),
        TextSpan(text: ' (${p.gender})',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: Color(0xFF666666), height: 1.2)),
        TextSpan(text: '  ${p.grade}',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: Color(0xFF5B8ABB), height: 1.2)),
      ]),
    );
  }
}

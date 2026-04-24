import 'package:flutter/material.dart';
import '../../members/domain/models/member_item.dart';
import 'tournament_models.dart';

class CourtSection extends StatelessWidget {
  final int courtNo;
  final List<TournamentMatch> matches;
  const CourtSection({super.key, required this.courtNo, required this.matches});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4D8DE), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0A245C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_tennis_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  '$courtNo 코트',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${matches.length}경기',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...matches.asMap().entries.map((entry) {
            return Column(
              children: [
                if (entry.key > 0)
                  const Divider(
                    height: 1,
                    color: Color(0xFFECEFF4),
                    indent: 16,
                  ),
                MatchBlock(
                  match: entry.value,
                  gameNum: entry.key + 1,
                  showGameNum: matches.length > 1,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGameNum)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: match.roundType.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: match.roundType.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$gameNum게임  ${match.roundType.label}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: match.roundType.color,
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TeamBlock(team: match.teamA, label: 'A팀'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      width: 1,
                      height: 16,
                      color: const Color(0xFFDDE3EC),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 1,
                      height: 16,
                      color: const Color(0xFFDDE3EC),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TeamBlock(team: match.teamB, label: 'B팀'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FB),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFB8D0EC)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B8ABB),
            ),
          ),
        ),
        const SizedBox(height: 4),
        PlayerLine(player: team.p1),
        const SizedBox(height: 3),
        PlayerLine(player: team.p2),
      ],
    );
  }
}

class PlayerLine extends StatelessWidget {
  final MemberItem? player;
  const PlayerLine({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    if (p == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          '부전승',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFBBBBBB),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Row(
      children: [
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: p.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                TextSpan(
                  text: ' (${p.gender})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFB8D0EC)),
          ),
          child: Text(
            p.grade,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5B8ABB),
            ),
          ),
        ),
      ],
    );
  }
}

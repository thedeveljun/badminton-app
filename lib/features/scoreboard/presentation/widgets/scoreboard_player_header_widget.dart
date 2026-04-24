import 'package:flutter/material.dart';

class ScoreboardPlayerHeaderWidget extends StatelessWidget {
  final String player1;
  final String player2;
  final bool player1Serving;
  final bool player2Serving;
  final VoidCallback onEditTeam;

  const ScoreboardPlayerHeaderWidget({
    super.key,
    required this.player1,
    required this.player2,
    required this.player1Serving,
    required this.player2Serving,
    required this.onEditTeam,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery 대신 LayoutBuilder로 부모 크기 기준 → 여백 오차 없음
    return LayoutBuilder(
      builder: (context, constraints) {
        final double headerH = (constraints.maxWidth * 0.11).clamp(36.0, 56.0);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEditTeam,
          child: Container(
            height: headerH,
            decoration: BoxDecoration(
              color: const Color(0xFF5F5F5F),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _playerLabel(player1, player1Serving)),
                Expanded(child: _playerLabel(player2, player2Serving)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _playerLabel(String name, bool isServing) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isServing ? const Color(0xFFB8FF48) : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomeIntroCard extends StatelessWidget {
  const HomeIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE), // primaryLight 대체
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '클럽 운영을 더 쉽고 편하게',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1246C8),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '배드민턴 클럽 관리 앱',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '회원관리, 대진표, 점수판, 이벤트까지\n클럽 운영에 필요한 기능을 한 곳에서\n차근차근 사용할 수 있게 준비합니다.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF737C8B),
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
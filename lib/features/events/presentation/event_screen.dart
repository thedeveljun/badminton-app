import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        surfaceTintColor: const Color(0xFFF6F7FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '이벤트',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration_outlined,
                  size: 64,
                  color: Color(0xFFBBBBBB),
                ),
                SizedBox(height: 12),
                Text(
                  '이벤트 기능 준비 중',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444444),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '클럽 대회·행사 운영을 위한 기능이\n다음 단계에서 제공됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

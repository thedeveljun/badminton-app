import 'package:flutter/material.dart';

class FreeScoreboardScreen extends StatelessWidget {
  const FreeScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('점수판')),
      body: const Center(
        child: Text(
          '점수판 화면\n다음 단계에서 연결합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

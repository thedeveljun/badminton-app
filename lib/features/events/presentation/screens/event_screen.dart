import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이벤트')),
      body: const Center(
        child: Text(
          '이벤트 화면\n다음 단계에서 연결합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'features/home/presentation/screens/main_home_screen.dart';
import 'features/home/presentation/widgets/home_intro_card.dart';

class FunmintonClubApp extends StatelessWidget {
  const FunmintonClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '배드민턴 클럽 관리',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5DB8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FA),
        fontFamily: 'Pretendard',
      ),
      // Navigator 이벤트 감지 — HomeIntroCard가 뒤로가기 감지하도록
      navigatorObservers: [HomeIntroCard.routeObserver],
      // 시스템 폰트 크기 변경이 과도하게 적용되지 않도록 제한
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(1.0).clamp(0.9, 1.15),
            ),
          ),
          child: child!,
        );
      },
      home: const MainHomeScreen(),
    );
  }
}

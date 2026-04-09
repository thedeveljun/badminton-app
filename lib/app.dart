import 'package:flutter/material.dart';
import 'features/home/presentation/screens/main_home_screen.dart';

class FunmintonApp extends StatelessWidget {
  const FunmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Funminton Club App',
      theme: ThemeData(useMaterial3: true),
      home: MainHomeScreen(),
    );
  }
}

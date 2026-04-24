import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle homeTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.black,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle introTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.black,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static const TextStyle introBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.introSubText,
    height: 1.5,
    letterSpacing: -0.2,
  );

  static const TextStyle menuCardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.blue,
    height: 1.1,
    letterSpacing: -0.3,
  );

  static const TextStyle menuCardBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    height: 1.3,
    letterSpacing: -0.1,
  );
}

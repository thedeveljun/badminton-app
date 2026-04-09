import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeIntroCard extends StatelessWidget {
  const HomeIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '클럽 운영을 더 쉽고 편하게',
            style: AppTextStyles.introBadge,
          ),
          SizedBox(height: 10),
          Text(
            '배드민턴 클럽 관리 앱',
            style: AppTextStyles.introTitle,
          ),
          SizedBox(height: 14),
          Text(
            '회원관리, 대진표, 점수판, 이벤트까지\n클럽 운영에 필요한 기능을 한 곳에서\n차근차근 사용할 수 있게 준비합니다.',
            style: AppTextStyles.introBody,
          ),
        ],
      ),
    );
  }
}
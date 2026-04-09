import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight2,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.menuCardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.menuCardSubtitle,
              ),
              const Spacer(),
              const Row(
                children: [
                  Text(
                    '바로가기',
                    style: AppTextStyles.linkText,
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// 작은 상태 표시 뱃지
///
/// ```dart
/// AppBadge.recruiting(true)   // 초록 '모집중'
/// AppBadge.recruiting(false)  // 회색 '모집마감'
/// AppBadge.notice()           // 보라 '공지'
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  factory AppBadge.recruiting(bool isRecruiting, {Key? key}) {
    return AppBadge(
      key: key,
      label: isRecruiting ? '모집중' : '모집마감',
      color: isRecruiting ? AppColors.recruiting : AppColors.closed,
      backgroundColor: isRecruiting
          ? AppColors.recruitingBackground
          : AppColors.closedBackground,
    );
  }

  factory AppBadge.notice({Key? key}) {
    return AppBadge(
      key: key,
      label: '공지',
      color: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
    );
  }

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

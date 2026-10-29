import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// 작은 상태 표시 뱃지
///
/// ```dart
/// AppBadge.recruiting(true)   // 차콜 '모집 중'
/// AppBadge.recruiting(false)  // 회색 '모집 마감'
/// AppBadge.category('학술')    // 베이지 카테고리 태그
/// AppBadge.notice()           // 캐러멜 '공지'
/// ```
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.bold = true,
  });

  factory AppBadge.recruiting(bool isRecruiting, {Key? key}) {
    return AppBadge(
      key: key,
      label: isRecruiting ? '모집 중' : '모집 마감',
      color: isRecruiting ? AppColors.recruiting : AppColors.closed,
      backgroundColor: isRecruiting
          ? AppColors.recruitingBackground
          : AppColors.closedBackground,
    );
  }

  factory AppBadge.category(String category, {Key? key}) {
    return AppBadge(
      key: key,
      label: category,
      color: AppColors.textSecondary,
      backgroundColor: AppColors.tagBackground,
      bold: false,
    );
  }

  /// 게시물 종류: 공지는 캐러멜, 모집·홍보는 베이지
  factory AppBadge.postType(String label, {required bool isNotice, Key? key}) {
    return AppBadge(
      key: key,
      label: label,
      color: isNotice ? AppColors.surface : AppColors.textSecondary,
      backgroundColor: isNotice ? AppColors.accent : AppColors.tagBackground,
      bold: isNotice,
    );
  }

  factory AppBadge.notice({Key? key}) {
    return AppBadge(
      key: key,
      label: '공지',
      color: AppColors.surface,
      backgroundColor: AppColors.accent,
    );
  }

  final String label;
  final Color color;
  final Color backgroundColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

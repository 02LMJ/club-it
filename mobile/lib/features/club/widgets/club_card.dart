import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/club.dart';

/// 동아리 목록 카드 (화면 설계 v2 S03-D4)
/// 동아리명 + 모집 뱃지 / 카테고리 / 한 줄 소개 / 즐겨찾기 별
class ClubCard extends StatelessWidget {
  const ClubCard({
    super.key,
    required this.club,
    required this.isFavorite,
    required this.onFavoritePressed,
    this.onTap,
  });

  final Club club;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(Icons.groups, color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.gapL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        club.name,
                        style: AppTextStyles.subtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.gapS),
                    AppBadge.recruiting(club.isRecruiting),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  club.category,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.gapS),
                Text(
                  club.summary,
                  style: AppTextStyles.bodySecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavoritePressed,
            tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppColors.favorite : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

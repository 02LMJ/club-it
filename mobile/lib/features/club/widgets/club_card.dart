import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/club.dart';

/// 동아리 목록 카드 (차콜·아이보리 시안)
/// [카테고리][모집 중]           ☆
/// 동아리명
/// 소개 (최대 2줄)
/// 👥 멤버 N명
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
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge.category(club.category),
              const SizedBox(width: 6),
              AppBadge.recruiting(club.isRecruiting),
              const Spacer(),
              IconButton(
                onPressed: onFavoritePressed,
                tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: isFavorite ? AppColors.favorite : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapS),
                Text(
                  club.description.isNotEmpty ? club.description : club.summary,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapM),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text('멤버 ${club.memberCount}명',
                        style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/post.dart';

/// 게시판 목록의 게시물 한 줄
/// [공지] 제목
/// 본문 미리보기 (2줄)
/// 작성자 · 날짜 · 💬 N
class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.caption.copyWith(color: AppColors.textHint);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge.postType(post.typeLabel, isNotice: post.isNotice),
              const SizedBox(width: AppSizes.gapS),
              Expanded(
                child: Text(
                  post.title,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            post.content,
            style: AppTextStyles.bodySecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.gapM),
          Row(
            children: [
              Text(post.authorName, style: meta),
              Text('  ·  ', style: meta),
              Text(formatShortDate(post.createdAt), style: meta),
              const Spacer(),
              const Icon(Icons.chat_bubble_outline,
                  size: 15, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: meta),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/app_notification.dart';
import 'notification_provider.dart';

/// S08 알림 탭
/// 새 게시물(즐겨찾기·알림 켠 동아리), 가입 승인·거절 알림 목록
/// - 누르면 읽음 처리, 게시물 알림이면 게시물로 이동
/// - 오른쪽 위 [모두 읽음]
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<void> _open(BuildContext context, AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    provider.markRead(n.id);
    if (n.postId != null) {
      await context.push(RoutePaths.postDetail(n.postId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: provider.unreadCount == 0 ? null : provider.markAllRead,
            child: const Text('모두 읽음'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.load,
        child: Builder(
          builder: (context) {
            if (provider.isLoading && items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  PlaceholderView(
                    icon: Icons.notifications_none_rounded,
                    title: provider.errorMessage ?? '아직 알림이 없어요',
                    message: provider.errorMessage == null
                        ? '즐겨찾기한 동아리의 새 글과\n가입 신청 결과를 여기서 알려드려요.'
                        : null,
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.gapS),
              itemBuilder: (context, index) {
                final n = items[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _open(context, n),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// 알림 한 건: 아이콘 / 메시지 / 시간, 안 읽은 알림은 굵게 + 캐러멜 점
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isPost = n.postId != null;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.tagBackground,
            child: Icon(
              isPost ? Icons.article_outlined : Icons.how_to_reg_outlined,
              size: 20,
              color: n.isRead ? AppColors.textHint : AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.message,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700,
                    color: n.isRead
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(formatShortDate(n.createdAt),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          if (!n.isRead)
            Container(
              key: const ValueKey('unread-dot'),
              margin: const EdgeInsets.only(left: AppSizes.gapS, top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

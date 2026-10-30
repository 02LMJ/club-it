import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/my_membership.dart';
import '../auth/auth_provider.dart';
import 'membership_provider.dart';

/// S09 마이 탭
/// 내 정보 / 가입한 동아리 / 가입 신청 현황(대기·거절+사유) / 로그아웃
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await showConfirmDialog(
      context,
      title: '로그아웃',
      message: '로그아웃할까요?',
      confirmLabel: '로그아웃',
    );
    if (ok) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final memberships = context.watch<MembershipProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: memberships.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            // 내 정보
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.tagBackground,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0] : '?',
                      style: AppTextStyles.title,
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '-', style: AppTextStyles.subtitle),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),

            ..._buildMemberships(context, memberships),

            const SizedBox(height: AppSizes.gapXL),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('디자인 미리보기 (개발용)'),
                    onTap: () => context.push(RoutePaths.designPreview),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('로그아웃'),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMemberships(
    BuildContext context,
    MembershipProvider provider,
  ) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.errorMessage != null) {
      return [
        Text(provider.errorMessage!,
            style: AppTextStyles.bodySecondary
                .copyWith(color: AppColors.error)),
      ];
    }

    return [
      _Section(
        title: '가입한 동아리',
        emptyText: '아직 가입한 동아리가 없어요.',
        items: provider.joined,
      ),
      const SizedBox(height: AppSizes.gapXL),
      _Section(
        title: '가입 신청 현황',
        emptyText: '진행 중인 가입 신청이 없어요.',
        items: provider.applications,
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<MyMembership> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title ${items.length}', style: AppTextStyles.label),
        const SizedBox(height: AppSizes.gapM),
        if (items.isEmpty)
          Text(emptyText,
              style: AppTextStyles.bodySecondary
                  .copyWith(color: AppColors.textHint))
        else
          for (final m in items) ...[
            _MembershipTile(membership: m),
            const SizedBox(height: AppSizes.gapS),
          ],
      ],
    );
  }
}

/// 신청 한 건: 동아리명·상태 뱃지 / 신청일 / (거절이면) 거절 사유
class _MembershipTile extends StatelessWidget {
  const _MembershipTile({required this.membership});

  final MyMembership membership;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    final (fg, bg) = switch (m.status) {
      'APPROVED' => (AppColors.surface, AppColors.primary),
      'PENDING' => (AppColors.surface, AppColors.accent),
      _ => (AppColors.closed, AppColors.closedBackground),
    };

    return AppCard(
      onTap: () => context.push(RoutePaths.clubDetail(m.clubId)),
      padding: const EdgeInsets.all(AppSizes.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m.clubName,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
              ),
              AppBadge(label: m.statusLabel, color: fg, backgroundColor: bg),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            m.status == 'APPROVED'
                ? '${formatShortDate(m.joinDate)} 가입'
                : '${formatShortDate(m.joinDate)} 신청',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          if (m.status == 'REJECTED' &&
              (m.rejectReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSizes.gapS),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.gapM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text('거절 사유: ${m.rejectReason}',
                  style: AppTextStyles.bodySecondary),
            ),
          ],
        ],
      ),
    );
  }
}

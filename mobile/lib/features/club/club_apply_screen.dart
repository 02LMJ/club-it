import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/placeholder_view.dart';
import '../auth/auth_provider.dart';
import 'club_provider.dart';

/// S05 가입 신청
/// 동아리 정보 / 신청자 정보(자동) / 신청 메시지(선택) / 신청하기
class ClubApplyScreen extends StatefulWidget {
  const ClubApplyScreen({super.key, required this.clubId});

  final int clubId;

  @override
  State<ClubApplyScreen> createState() => _ClubApplyScreenState();
}

class _ClubApplyScreenState extends State<ClubApplyScreen> {
  static const _maxLength = 300;

  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _completed = false; // 신청 성공 후 화면이 닫히는 동안 안내 문구가 깜빡이지 않도록
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit(String clubName) async {
    FocusScope.of(context).unfocus();
    final ok = await showConfirmDialog(
      context,
      title: '가입 신청',
      message: '$clubName에 가입 신청할까요?\n임원이 승인하면 알림으로 알려드려요.',
      confirmLabel: '신청',
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<ClubProvider>().applyJoin(
            widget.clubId,
            message: _messageController.text,
          );
      _completed = true;
      messenger.showSnackBar(
        const SnackBar(content: Text('가입 신청이 완료되었어요.')),
      );
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '알 수 없는 오류가 발생했어요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = context.watch<ClubProvider>().findById(widget.clubId);
    final user = context.watch<AuthProvider>().user;

    if (club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('가입 신청')),
        body: const PlaceholderView(title: '동아리를 찾을 수 없어요'),
      );
    }

    // 상세 화면에서 막고 있지만, 주소로 바로 들어온 경우를 위한 안전장치
    final blockedReason = _completed
        ? null
        : switch (club.myStatus) {
            'PENDING' => '이미 가입 신청한 동아리예요.',
            'APPROVED' => '이미 가입한 동아리예요.',
            _ when !club.isRecruiting => '지금은 모집 기간이 아니에요.',
            _ => null,
          };

    return Scaffold(
      appBar: AppBar(title: const Text('가입 신청')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            // 신청할 동아리
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppBadge.category(club.category),
                      const SizedBox(width: 6),
                      AppBadge.recruiting(club.isRecruiting),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Text(club.name,
                      style: AppTextStyles.title.copyWith(fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapL),

            // 신청자 정보 (로그인 정보로 자동 입력, 수정 불가)
            const Text('신청자 정보', style: AppTextStyles.label),
            const SizedBox(height: AppSizes.gapS),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(label: '이름', value: user?.name ?? '-'),
                  const SizedBox(height: AppSizes.gapS),
                  _InfoRow(label: '이메일', value: user?.email ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 신청 메시지 (선택)
            AppTextField(
              controller: _messageController,
              label: '신청 메시지 (선택)',
              hintText: '간단한 자기소개나 지원 동기를 적어주세요.',
              maxLines: 5,
              maxLength: _maxLength,
              enabled: blockedReason == null && !_isSubmitting,
            ),
            const SizedBox(height: AppSizes.gapM),

            if (blockedReason != null) ...[
              ErrorBanner(message: blockedReason),
              const SizedBox(height: AppSizes.gapM),
            ],
            if (_errorMessage != null) ...[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSizes.gapM),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppButton(
              label: '신청하기',
              isLoading: _isSubmitting,
              onPressed: blockedReason == null ? () => _submit(club.name) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: AppTextStyles.bodySecondary),
        ),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    );
  }
}

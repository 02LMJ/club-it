import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/club_application.dart';
import '../../data/repositories/club_admin_repository.dart';

/// S10 가입 신청 관리 (동아리 임원)
/// 대기 중인 신청 목록 → [승인] 또는 [거절](사유 입력)
/// 처리 결과는 서버가 신청자에게 알림으로 보냄
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.clubId});

  final int clubId;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<ClubApplication> _items = [];
  bool _isLoading = true;
  String? _error;

  /// 지금 처리 중인 신청 (버튼 중복 클릭 방지)
  int? _busyId;

  ClubAdminRepository get _repo => context.read<ClubAdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchApplications(widget.clubId);
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '신청 목록을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(ClubApplication a) async {
    final ok = await showConfirmDialog(
      context,
      title: '가입 승인',
      message: '${a.userName}님의 가입을 승인할까요?',
      confirmLabel: '승인',
    );
    if (!ok || !mounted) return;
    await _decide(a, approve: true);
  }

  Future<void> _reject(ClubApplication a) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(child: _RejectSheet(userName: a.userName)),
      ),
    );
    if (reason == null || !mounted) return;
    await _decide(a, approve: false, reason: reason);
  }

  Future<void> _decide(
    ClubApplication a, {
    required bool approve,
    String? reason,
  }) async {
    setState(() => _busyId = a.id);
    try {
      await _repo.decideApplication(
        widget.clubId,
        a.id,
        approve: approve,
        rejectReason: reason,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != a.id).toList();
      });
      _snack(approve
          ? '${a.userName}님의 가입을 승인했어요.'
          : '${a.userName}님의 신청을 거절했어요.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('처리하지 못했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가입 신청 관리')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          PlaceholderView(
            icon: _error == null
                ? Icons.inbox_outlined
                : Icons.wifi_off_rounded,
            title: _error ?? '대기 중인 가입 신청이 없어요',
            message: _error == null ? '새 신청이 오면 여기에 표시돼요.' : null,
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        Text('대기 중인 신청 ${_items.length}', style: AppTextStyles.label),
        const SizedBox(height: AppSizes.gapM),
        for (final a in _items) ...[
          _ApplicationCard(
            application: a,
            isBusy: _busyId == a.id,
            onApprove: _busyId == null ? () => _approve(a) : null,
            onReject: _busyId == null ? () => _reject(a) : null,
          ),
          const SizedBox(height: AppSizes.gapM),
        ],
      ],
    );
  }
}

/// 신청 한 건: 이름·이메일·신청일 / 지원 동기 / [거절] [승인]
class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final ClubApplication application;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final a = application;
    final message = a.message?.trim() ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.tagBackground,
                child: Text(
                  a.userName.isNotEmpty ? a.userName.characters.first : '?',
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(width: AppSizes.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.userName, style: AppTextStyles.subtitle),
                    Text(a.userEmail, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text('${formatDateTime(a.joinDate)} 신청',
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.gapM),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Text(
              message.isEmpty ? '작성한 지원 동기가 없어요.' : message,
              style: message.isEmpty
                  ? AppTextStyles.bodySecondary
                      .copyWith(color: AppColors.textHint)
                  : AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '거절',
                  variant: AppButtonVariant.outlined,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppSizes.gapS),
              Expanded(
                child: AppButton(
                  label: '승인',
                  isLoading: isBusy,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 거절 사유 입력 (신청자 마이페이지에 그대로 보여짐)
class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.userName});

  final String userName;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = '거절 사유를 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('가입 거절', style: AppTextStyles.subtitle),
          const SizedBox(height: 4),
          Text(
            '${widget.userName}님에게 거절 사유가 함께 전달돼요.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSizes.gapL),
          TextField(
            controller: _reason,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.body,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: '예) 이번 학기 모집 정원이 마감되었습니다.',
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          AppButton(label: '거절하기', onPressed: _submit),
        ],
      ),
    );
  }
}

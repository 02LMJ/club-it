import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/club_application.dart';
import '../../data/repositories/club_admin_repository.dart';

/// S11 부원 목록 (동아리 임원)
/// 승인된 부원을 임원 → 부원 순으로 보여줌 (이름·이메일·가입일)
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.clubId});

  final int clubId;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<ClubApplication> _members = [];
  bool _isLoading = true;
  String? _error;

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
      final members = await context
          .read<ClubAdminRepository>()
          .fetchMembers(widget.clubId);
      if (mounted) setState(() => _members = members);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '부원 목록을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부원 목록')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_members.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          PlaceholderView(
            icon: _error == null
                ? Icons.groups_outlined
                : Icons.wifi_off_rounded,
            title: _error ?? '아직 부원이 없어요',
          ),
        ],
      );
    }

    final officerCount = _members.where((m) => m.role == 'OFFICER').length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        Text(
          '부원 ${_members.length}명 · 임원 $officerCount명',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSizes.gapM),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _members.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 72, color: AppColors.border),
                _MemberTile(member: _members[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 부원 한 명: 이니셜 / 이름 [임원] · 이메일 / 가입일
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final ClubApplication member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final isOfficer = m.role == 'OFFICER';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.cardPadding,
        vertical: AppSizes.gapM,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isOfficer ? AppColors.primary : AppColors.tagBackground,
            child: Text(
              m.userName.isNotEmpty ? m.userName.characters.first : '?',
              style: AppTextStyles.label.copyWith(
                color: isOfficer ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.userName,
                        style: AppTextStyles.subtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOfficer) ...[
                      const SizedBox(width: 6),
                      const AppBadge(
                        label: '임원',
                        color: AppColors.accent,
                        backgroundColor: AppColors.tagBackground,
                      ),
                    ],
                  ],
                ),
                Text(m.userEmail, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('${formatDate(m.joinDate)} 가입',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

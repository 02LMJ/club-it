import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/repositories/club_admin_repository.dart';
import '../club/club_provider.dart';
import '../auth/auth_provider.dart';

/// S12 동아리 등록·수정 (OFFICER 권한 사용자 / 동아리 임원)
/// - clubId가 없으면 새 동아리 등록, 있으면 기존 정보 수정
/// - 이름 / 분야 / 소개 / 모집 중 여부, 오른쪽 위 [등록]·[저장]
/// - 수정일 때 맨 아래 [동아리 삭제] (관리자만)
class ClubFormScreen extends StatefulWidget {
  const ClubFormScreen({super.key, this.clubId});

  final int? clubId;

  bool get isEdit => clubId != null;

  @override
  State<ClubFormScreen> createState() => _ClubFormScreenState();
}

class _ClubFormScreenState extends State<ClubFormScreen> {
  /// 분야 선택지 (홈 화면 카테고리 칩과 같은 순서)
  static const _presetCategories = ['학술', '봉사', '예술', '체육', '종교', '취미', '기타'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();

  String _category = '학술';
  bool _isRecruiting = true;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  ClubAdminRepository get _repo => context.read<ClubAdminRepository>();

  /// 기존 분야가 선택지에 없으면 함께 보여줌
  List<String> get _categories => _presetCategories.contains(_category)
      ? _presetCategories
      : [..._presetCategories, _category];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadClub();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// 수정: 서버에서 최신 정보를 받아 입력칸에 채움
  Future<void> _loadClub() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final club =
          await context.read<ClubProvider>().fetchClubDetail(widget.clubId!);
      if (!mounted) return;
      setState(() {
        _name.text = club.name;
        _category = club.category;
        _description.text = club.description;
        _isRecruiting = club.isRecruiting;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = '동아리 정보를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final clubs = context.read<ClubProvider>();
    final router = GoRouter.of(context);
    final name = _name.text.trim();
    final description = _description.text.trim();
    setState(() => _isSaving = true);
    try {
      if (widget.isEdit) {
        await _repo.updateClub(
          widget.clubId!,
          name: name,
          category: _category,
          description: description,
          isRecruiting: _isRecruiting,
        );
        clubs.loadClubs(); // 홈 목록에도 반영
        if (!mounted) return;
        _snack('동아리 정보를 수정했어요.');
        router.pop(true);
      } else {
        final club = await _repo.createClub(
          name: name,
          category: _category,
          description: description,
          isRecruiting: _isRecruiting,
        );
        clubs.loadClubs();
        if (!mounted) return;
        _snack('동아리를 등록했어요.');
        // 등록 화면 대신 새 동아리 상세로
        router.pushReplacement(RoutePaths.clubDetail(club.id));
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('저장하지 못했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: '동아리 삭제',
      message: '${_name.text.trim()}을(를) 삭제할까요?\n목록에서 사라지고 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final clubs = context.read<ClubProvider>();
    final router = GoRouter.of(context);
    setState(() => _isSaving = true);
    try {
      await _repo.deleteClub(widget.clubId!);
      clubs.loadClubs();
      if (!mounted) return;
      _snack('동아리를 삭제했어요.');
      router.go(RoutePaths.home); // 지워진 동아리 상세로 돌아가지 않도록 홈으로
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('삭제하지 못했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '동아리 정보 수정' : '동아리 등록';

    if (_isLoading || _loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PlaceholderView(icon: Icons.wifi_off_rounded, title: _loadError!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEdit ? '저장' : '등록'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _name,
                label: '동아리 이름',
                hintText: '예) CATS',
                maxLength: 100,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '동아리 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: AppSizes.gapM),
              Text('분야', style: AppTextStyles.label),
              const SizedBox(height: AppSizes.gapS),
              Wrap(
                spacing: AppSizes.gapS,
                runSpacing: AppSizes.gapS,
                children: [
                  for (final c in _categories)
                    CategoryChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.gapXL),
              AppTextField(
                controller: _description,
                label: '동아리 소개',
                hintText: '어떤 활동을 하는 동아리인지 소개해주세요.\n첫 줄은 목록에 한 줄 소개로 보여요.',
                maxLines: 8,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppSizes.gapM),
              AppCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  title: Text('신입 부원 모집 중', style: AppTextStyles.body),
                  subtitle: Text(
                    _isRecruiting
                        ? '학생들이 가입 신청을 할 수 있어요.'
                        : '가입 신청 버튼이 "모집 기간이 아닙니다"로 바뀌어요.',
                    style: AppTextStyles.caption,
                  ),
                  value: _isRecruiting,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isRecruiting = v),
                ),
              ),
              // 동아리 삭제는 관리자만 (임원이 실수로 지우지 않도록)
              if (widget.isEdit &&
                  (context.watch<AuthProvider>().user?.isAdmin ?? false)) ...[
                const SizedBox(height: AppSizes.gapXL),
                Center(
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('동아리 삭제'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/repositories/post_repository.dart';

/// S07 게시물 작성·수정 (동아리 임원)
/// - clubId만 주면 새 글 작성, postId를 주면 기존 글 수정
/// - 종류(공지·모집·홍보) / 제목 / 내용, 오른쪽 위 [등록]·[저장]
/// - 저장에 성공하면 true를 돌려주며 닫힘 (이전 화면이 목록을 새로고침)
class PostEditScreen extends StatefulWidget {
  const PostEditScreen({super.key, this.clubId, this.postId})
      : assert(clubId != null || postId != null);

  final int? clubId;
  final int? postId;

  bool get isEdit => postId != null;

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  /// (서버 post_type, 화면 글자)
  static const _types = <(String, String)>[
    ('NOTICE', '공지'),
    ('RECRUIT', '모집'),
    ('PROMO', '홍보'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  String _type = 'NOTICE';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  /// 처음 상태 (나갈 때 바뀐 내용이 있는지 비교용)
  String _initial = '';

  PostRepository get _repo => context.read<PostRepository>();

  String get _snapshot => '$_type|${_title.text}|${_content.text}';
  bool get _isDirty => _snapshot != _initial;

  @override
  void initState() {
    super.initState();
    _initial = _snapshot;
    // 입력할 때마다 다시 그려서, 뒤로 가기 확인 여부(_isDirty)를 최신으로 유지
    _title.addListener(_onChanged);
    _content.addListener(_onChanged);
    if (widget.isEdit) _loadPost();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  /// 수정: 기존 글을 불러와 입력창에 채움
  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final post = await _repo.fetchPost(widget.postId!);
      if (!mounted) return;
      setState(() {
        _type = post.type;
        _title.text = post.title;
        _content.text = post.content;
        _initial = _snapshot;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = '게시물을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final title = _title.text.trim();
      final content = _content.text.trim();
      if (widget.isEdit) {
        await _repo.updatePost(widget.postId!,
            type: _type, title: title, content: content);
      } else {
        await _repo.createPost(widget.clubId!,
            type: _type, title: title, content: content);
      }
      _initial = _snapshot; // 저장했으니 나갈 때 확인 창 안 띄움
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isEdit ? '게시물을 수정했어요.' : '게시물을 등록했어요.'),
      ));
      navigator.pop(true);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 작성 중에 뒤로 가면 확인
  Future<void> _confirmLeave() async {
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: '작성 취소',
      message: '작성 중인 내용이 사라져요. 나갈까요?',
      confirmLabel: '나가기',
      cancelLabel: '계속 쓰기',
      destructive: true,
    );
    if (ok && mounted) {
      _initial = _snapshot;
      navigator.pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '게시물 수정' : '게시물 작성';

    if (_isLoading || _loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PlaceholderView(icon: Icons.wifi_off_rounded, title: _loadError!),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
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
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            children: [
              Text('게시물 종류', style: AppTextStyles.label),
              const SizedBox(height: AppSizes.gapS),
              Wrap(
                spacing: AppSizes.gapS,
                children: [
                  for (final (type, label) in _types)
                    CategoryChip(
                      label: label,
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.gapXL),
              AppTextField(
                controller: _title,
                label: '제목',
                hintText: '제목을 입력해주세요',
                maxLength: 200,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '제목을 입력해주세요.' : null,
              ),
              const SizedBox(height: AppSizes.gapM),
              AppTextField(
                controller: _content,
                label: '내용',
                hintText: '동아리원과 학생들에게 전할 내용을 적어주세요',
                maxLines: 12,
                keyboardType: TextInputType.multiline,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? '내용을 입력해주세요.' : null,
              ),
              if (!widget.isEdit) ...[
                const SizedBox(height: AppSizes.gapM),
                Text(
                  '글을 올리면 이 동아리를 즐겨찾기한 학생들에게 알림이 가요.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

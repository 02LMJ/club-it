import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../auth/auth_provider.dart';
import '../club/club_provider.dart';

/// S06 게시물 상세
/// 종류 뱃지·제목 / 작성자·날짜 / 본문 / 댓글 목록 / 하단 고정 댓글 입력창
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  /// 수정 중인 댓글 (null이면 새 댓글 작성 모드)
  Comment? _editing;

  PostRepository get _repo => context.read<PostRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchPost(widget.postId),
        _repo.fetchComments(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as Post;
        _comments = results[1] as List<Comment>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '게시물을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 등록 버튼: 새 댓글 작성 또는 수정 저장
  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final editing = _editing;
      if (editing == null) {
        final created = await _repo.addComment(widget.postId, content);
        if (!mounted) return;
        setState(() => _comments = [..._comments, created]);
      } else {
        final updated = await _repo.updateComment(editing.id, content);
        if (!mounted) return;
        setState(() {
          _comments = [
            for (final c in _comments) c.id == updated.id ? updated : c,
          ];
          _editing = null;
        });
      }
      _inputController.clear();
      FocusScope.of(context).unfocus();
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startEdit(Comment comment) {
    setState(() => _editing = comment);
    _inputController.text = comment.content;
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _inputController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _delete(Comment comment) async {
    final ok = await showConfirmDialog(
      context,
      title: '댓글 삭제',
      message: '이 댓글을 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
        if (_editing?.id == comment.id) _cancelEdit();
      });
      _showSnack('댓글을 삭제했어요.');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final myId = context.watch<AuthProvider>().user?.id;
    final isOfficer = post != null &&
        (context.watch<ClubProvider>().findById(post.clubId)?.isOfficer ??
            false);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PlaceholderView(
                icon: Icons.wifi_off_rounded,
                title: _errorMessage ?? '게시물을 찾을 수 없어요.',
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _PostBody(post: post),
            const SizedBox(height: AppSizes.gapXL),
            const Divider(),
            const SizedBox(height: AppSizes.gapL),
            Text('댓글 ${_comments.length}', style: AppTextStyles.label),
            const SizedBox(height: AppSizes.gapM),
            if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '첫 댓글을 남겨 보세요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary
                      .copyWith(color: AppColors.textHint),
                ),
              )
            else
              for (final comment in _comments)
                _CommentTile(
                  comment: comment,
                  isMine: comment.authorId == myId,
                  canDelete: comment.authorId == myId || isOfficer,
                  onEdit: () => _startEdit(comment),
                  onDelete: () => _delete(comment),
                ),
          ],
        ),
      ),
      bottomNavigationBar: _CommentInput(
        controller: _inputController,
        focusNode: _inputFocus,
        editing: _editing != null,
        isSending: _isSending,
        onSend: _send,
        onCancelEdit: _cancelEdit,
      ),
    );
  }
}

/// 게시물 본문 영역
class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.caption.copyWith(color: AppColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBadge.postType(post.typeLabel, isNotice: post.isNotice),
        const SizedBox(height: AppSizes.gapM),
        Text(post.title, style: AppTextStyles.headline),
        const SizedBox(height: AppSizes.gapS),
        Row(
          children: [
            Text(post.authorName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary)),
            Text('  ·  ', style: meta),
            Text(formatShortDate(post.createdAt), style: meta),
          ],
        ),
        const SizedBox(height: AppSizes.gapXL),
        SelectableText(post.content, style: AppTextStyles.body),
      ],
    );
  }
}

/// 댓글 한 개: 작성자·날짜 / 내용 / ⋮ (내 댓글: 수정·삭제, 임원: 삭제)
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Comment comment;
  final bool isMine;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.caption.copyWith(color: AppColors.textHint);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.tagBackground,
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0] : '?',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: AppTextStyles.label.copyWith(fontSize: 14)),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Text('나', style: meta.copyWith(color: AppColors.accent)),
                    ],
                    const SizedBox(width: 8),
                    Text(formatShortDate(comment.createdAt), style: meta),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: AppTextStyles.body),
              ],
            ),
          ),
          if (canDelete)
            PopupMenuButton<String>(
              tooltip: '댓글 메뉴',
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.textHint),
              color: AppColors.surface,
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                if (isMine)
                  const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 하단 고정 댓글 입력창 (수정 중이면 상단에 안내 + 취소)
class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.isSending,
    required this.onSend,
    required this.onCancelEdit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editing)
                Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('댓글 수정 중', style: AppTextStyles.caption),
                    const Spacer(),
                    TextButton(
                      onPressed: onCancelEdit,
                      child: const Text('취소'),
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      enabled: !isSending,
                      textInputAction: TextInputAction.newline,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요',
                        counterText: '',
                        isDense: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: editing ? '수정 저장' : '댓글 등록',
                          onPressed: onSend,
                          icon: Icon(
                            editing ? Icons.check_rounded : Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

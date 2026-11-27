import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/ai_repository.dart';

/// 게시물 작성 화면의 "AI 작성 도우미"
///
/// - 초안 만들기: 키워드·메모 → 본문 초안
/// - 제목 추천: 본문 → 제목 후보 중 골라서 제목에 넣기
/// - 문장 다듬기: 본문 → 다듬은 글
/// - 요약하기: 본문 → 2~3문장 요약 (복사)
///
/// AI 결과는 바로 넣지 않고, 아래에서 올라오는 창에서 **확인·수정한 뒤** 적용한다.
class AiAssistPanel extends StatefulWidget {
  const AiAssistPanel({
    super.key,
    required this.postType,
    required this.titleController,
    required this.contentController,
    this.clubId,
  });

  /// NOTICE / RECRUIT / PROMO (글 종류에 맞는 문체로 생성)
  final String postType;

  /// 동아리 이름·소개를 AI에 함께 알려줄 때 사용
  final int? clubId;
  final TextEditingController titleController;
  final TextEditingController contentController;

  @override
  State<AiAssistPanel> createState() => _AiAssistPanelState();
}

class _AiAssistPanelState extends State<AiAssistPanel> {
  /// 지금 AI 응답을 기다리는 작업 (null이면 대기 중 아님)
  AiTask? _running;

  static const _icons = {
    AiTask.draft: Icons.auto_awesome_outlined,
    AiTask.title: Icons.title_rounded,
    AiTask.improve: Icons.spellcheck_rounded,
    AiTask.summary: Icons.short_text_rounded,
  };

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(AiTask task) async {
    if (_running != null) return;
    final content = widget.contentController.text.trim();

    // 1) 보낼 내용 정하기
    String text;
    if (task == AiTask.draft) {
      final memo = await _showSheet<String>(
        _MemoSheet(initial: content),
      );
      if (memo == null || !mounted) return;
      text = memo;
    } else {
      if (content.isEmpty) {
        _snack('본문을 먼저 입력해주세요.');
        return;
      }
      text = content;
    }

    // 2) AI 요청
    setState(() => _running = task);
    AiResult result;
    try {
      result = await context.read<AiRepository>().assist(
            task: task,
            postType: widget.postType,
            text: text,
            clubId: widget.clubId,
          );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
      return;
    } catch (_) {
      if (mounted) _snack('AI 응답을 받지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    } finally {
      if (mounted) setState(() => _running = null);
    }
    if (!mounted) return;

    // 3) 결과 확인·수정 → 적용
    switch (task) {
      case AiTask.title:
        final picked = await _showSheet<String>(_TitleSheet(result: result));
        if (picked != null) widget.titleController.text = picked;
      case AiTask.draft:
      case AiTask.improve:
        final edited = await _showSheet<String>(_ResultSheet(
          task: task,
          result: result,
          applyLabel: task == AiTask.draft ? '본문에 넣기' : '이 글로 바꾸기',
        ));
        if (edited != null) widget.contentController.text = edited;
      case AiTask.summary:
        final edited = await _showSheet<String>(_ResultSheet(
          task: task,
          result: result,
          applyLabel: '복사하기',
        ));
        if (edited != null) {
          await Clipboard.setData(ClipboardData(text: edited));
          if (mounted) _snack('요약을 복사했어요.');
        }
    }
  }

  Future<T?> _showSheet<T>(Widget sheet) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (context) => Padding(
        // 키보드가 올라오면 창도 같이 올라가도록
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(child: sheet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('AI 작성 도우미', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '결과를 확인하고 고친 뒤에 글에 넣을 수 있어요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppSizes.gapM),
          Wrap(
            spacing: AppSizes.gapS,
            runSpacing: AppSizes.gapS,
            children: [
              for (final task in [
                AiTask.draft,
                AiTask.title,
                AiTask.improve,
                AiTask.summary,
              ])
                ActionChip(
                  onPressed: _running == null ? () => _run(task) : null,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  avatar: _running == task
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_icons[task],
                          size: 18, color: AppColors.textPrimary),
                  label: Text(task.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 창 제목 + 예시 응답 안내
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.isMock = false});

  final String title;
  final bool isMock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subtitle),
        if (isMock) ...[
          const SizedBox(height: 4),
          Text(
            '지금은 서버가 예시 응답 모드라 실제 AI 결과가 아니에요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
          ),
        ],
        const SizedBox(height: AppSizes.gapL),
      ],
    );
  }
}

/// 초안 만들기: 키워드·메모 입력
class _MemoSheet extends StatefulWidget {
  const _MemoSheet({required this.initial});

  final String initial;

  @override
  State<_MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<_MemoSheet> {
  late final _memo = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHeader(title: '초안 만들기'),
          TextField(
            controller: _memo,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 5000,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              hintText: '예) 신입 모집, 12월 1일~7일, 초보 환영, 매주 목요일 스터디',
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          AppButton(
            label: 'AI로 초안 만들기',
            icon: Icons.auto_awesome_outlined,
            onPressed: () {
              final memo = _memo.text.trim();
              if (memo.isEmpty) return;
              Navigator.of(context).pop(memo);
            },
          ),
        ],
      ),
    );
  }
}

/// 제목 추천: 후보 중 하나를 누르면 제목에 넣음
class _TitleSheet extends StatelessWidget {
  const _TitleSheet({required this.result});

  final AiResult result;

  @override
  Widget build(BuildContext context) {
    final items = result.suggestions.isNotEmpty
        ? result.suggestions
        : result.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: '제목 추천', isMock: result.isMock),
          if (items.isEmpty)
            Text('추천할 제목을 찾지 못했어요.', style: AppTextStyles.bodySecondary)
          else
            for (final title in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: AppTextStyles.body),
                trailing: const Icon(Icons.north_west_rounded,
                    size: 18, color: AppColors.textHint),
                onTap: () => Navigator.of(context).pop(title),
              ),
        ],
      ),
    );
  }
}

/// 초안·다듬기·요약 결과: 직접 고친 뒤 [적용]
class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.task,
    required this.result,
    required this.applyLabel,
  });

  final AiTask task;
  final AiResult result;
  final String applyLabel;

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  late final _text = TextEditingController(text: widget.result.text.trim());

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: widget.task.label, isMock: widget.result.isMock),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: TextField(
              controller: _text,
              minLines: 4,
              maxLines: null,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                helperText: '필요하면 직접 고친 뒤 적용하세요.',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '닫기',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSizes.gapS),
              Expanded(
                child: AppButton(
                  label: widget.applyLabel,
                  onPressed: () {
                    final text = _text.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(context).pop(text);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

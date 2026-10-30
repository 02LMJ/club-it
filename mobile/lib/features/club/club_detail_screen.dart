import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/club.dart';
import '../../data/models/post.dart';
import '../post/widgets/post_tile.dart';
import 'club_provider.dart';
import 'favorite_action.dart';

/// S04 동아리 상세
/// 헤더(태그·이름·멤버 수) / [소개]·[게시판] 탭 / 가입 상태별 하단 버튼
class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final int clubId;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  Club? _club;
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 목록에서 이미 받아둔 정보가 있으면 먼저 보여주고, 서버에서 최신 정보로 갱신
    _club = context.read<ClubProvider>().findById(widget.clubId);
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<ClubProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        provider.fetchClubDetail(widget.clubId),
        provider.fetchPosts(widget.clubId),
      ]);
      if (!mounted) return;
      setState(() {
        _club = results[0] as Club;
        _posts = results[1] as List<Post>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '동아리 정보를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openApply(Club club) async {
    await context.push(RoutePaths.clubApply(club.id));
    // 신청 화면에서 돌아오면 가입 상태가 바뀌었을 수 있으니 다시 조회
    if (mounted) _load();
  }

  /// 게시물을 보고 돌아오면 댓글 수가 바뀌었을 수 있으니 다시 조회
  Future<void> _openPost(Post post) async {
    await context.push(RoutePaths.postDetail(post.id));
    if (mounted) _load();
  }

  Future<void> _cancelJoin(Club club) async {
    final ok = await showConfirmDialog(
      context,
      title: '신청 취소',
      message: '${club.name} 가입 신청을 취소할까요?',
      confirmLabel: '신청 취소',
      cancelLabel: '닫기',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCancelling = true);
    try {
      final updated = await context.read<ClubProvider>().cancelJoin(club.id);
      if (!mounted) return;
      setState(() => _club = updated);
      messenger.showSnackBar(
        const SnackBar(content: Text('가입 신청을 취소했어요.')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = _club;
    final isFavorite = context.watch<ClubProvider>().isFavorite(widget.clubId);

    if (club == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ErrorView(
                message: _errorMessage ?? '동아리를 찾을 수 없어요.',
                onRetry: _load,
              ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
              onPressed: () => toggleFavoriteWithFeedback(context, club.id),
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 28,
                color: isFavorite ? AppColors.favorite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(club: club),
            TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.label,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: AppColors.border,
              tabs: [
                const Tab(text: '소개'),
                Tab(text: '게시판 ${_posts.length}'),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(_errorMessage!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.error)),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _IntroTab(club: club),
                  _PostsTab(
                    posts: _posts,
                    isLoading: _isLoading,
                    onRefresh: _load,
                    onOpen: _openPost,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomAction(
          club: club,
          onApply: () => _openApply(club),
          onCancel: () => _cancelJoin(club),
          isBusy: _isCancelling,
        ),
      ),
    );
  }
}

/// 상단: [학술][모집 중] / 동아리명 / 멤버 N명 · 임원
class _Header extends StatelessWidget {
  const _Header({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
          const SizedBox(height: AppSizes.gapM),
          Text(club.name, style: AppTextStyles.headline.copyWith(fontSize: 28)),
          const SizedBox(height: AppSizes.gapS),
          Row(
            children: [
              const Icon(Icons.people_outline,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('멤버 ${club.memberCount}명', style: AppTextStyles.caption),
              if (club.isOfficer) ...[
                const SizedBox(width: AppSizes.gapS),
                const AppBadge(
                  label: '임원',
                  color: AppColors.accent,
                  backgroundColor: AppColors.tagBackground,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// [소개] 탭: 동아리 소개 + 모집 정보
class _IntroTab extends StatelessWidget {
  const _IntroTab({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('동아리 소개', style: AppTextStyles.label),
              const SizedBox(height: AppSizes.gapS),
              Text(
                club.description.isNotEmpty
                    ? club.description
                    : '아직 등록된 소개가 없어요.',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.gapM),
        AppCard(
          child: Row(
            children: [
              Icon(
                club.isRecruiting
                    ? Icons.campaign_outlined
                    : Icons.event_busy_outlined,
                color: club.isRecruiting
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.gapM),
              Expanded(
                child: Text(
                  club.isRecruiting
                      ? '지금 신입 부원을 모집하고 있어요.'
                      : '현재 모집 기간이 아니에요. 즐겨찾기하면 새 소식을 받아볼 수 있어요.',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [게시판] 탭: 종류 필터(전체·공지·모집·홍보) + 게시물 목록 (최신순), 아래로 당겨 새로고침
class _PostsTab extends StatefulWidget {
  const _PostsTab({
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpen,
  });

  final List<Post> posts;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(Post post) onOpen;

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  /// 필터 칩: (서버 post_type, 화면 글자). null = 전체
  static const _types = <(String?, String)>[
    (null, '전체'),
    ('NOTICE', '공지'),
    ('RECRUIT', '모집'),
    ('PROMO', '홍보'),
  ];

  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 게시물은 이미 다 받아왔으니 앱에서 바로 거른다 (칩 누를 때마다 요청하지 않도록)
    final posts = _selectedType == null
        ? widget.posts
        : widget.posts.where((p) => p.type == _selectedType).toList();
    final emptyTitle = _selectedType == null
        ? '아직 게시물이 없어요'
        : '${_types.firstWhere((t) => t.$1 == _selectedType).$2} 게시물이 없어요';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            itemCount: _types.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.gapS),
            itemBuilder: (context, index) {
              final (type, label) = _types[index];
              return CategoryChip(
                label: label,
                selected: _selectedType == type,
                onTap: () => setState(() => _selectedType = type),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: widget.onRefresh,
            child: posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      PlaceholderView(
                        icon: Icons.article_outlined,
                        title: emptyTitle,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.gapM),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostTile(
                        post: post,
                        onTap: () => widget.onOpen(post),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// 하단 고정 영역 — 모집 여부(recruit_status) + 내 가입 상태(my_status)로 결정
/// - 대기 중: 안내 문구 + [신청 취소]
/// - 그 외: 상태에 맞는 버튼 하나
class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.club,
    required this.onApply,
    required this.onCancel,
    required this.isBusy,
  });

  final Club club;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (club.myStatus == 'PENDING') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '가입 신청 완료 · 임원 승인을 기다리고 있어요',
                  style: AppTextStyles.bodySecondary
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          AppButton(
            label: '신청 취소',
            variant: AppButtonVariant.outlined,
            isLoading: isBusy,
            onPressed: onCancel,
          ),
        ],
      );
    } else {
      final (label, onPressed) = switch (club.myStatus) {
        'APPROVED' => ('가입한 동아리예요', null),
        _ when !club.isRecruiting => ('모집 기간이 아닙니다', null),
        _ => ('가입 신청하기', onApply),
      };
      content = AppButton(label: label, isLoading: isBusy, onPressed: onPressed);
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: content,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlaceholderView(icon: Icons.wifi_off_rounded, title: message),
        AppButton(
          label: '다시 시도',
          variant: AppButtonVariant.outlined,
          fullWidth: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

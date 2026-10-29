import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/club_it_logo.dart';
import '../../core/widgets/placeholder_view.dart';
import '../../data/models/club.dart';
import 'club_provider.dart';
import 'favorite_action.dart';
import 'widgets/club_card.dart';

/// S03 동아리 목록 (홈 탭) — 차콜·아이보리 시안
/// 로고 / 큰 제목 / 검색 / 카테고리 칩 / 'N개 + 모집 중만' / 카드 목록
class ClubListScreen extends StatefulWidget {
  const ClubListScreen({super.key});

  @override
  State<ClubListScreen> createState() => _ClubListScreenState();
}

class _ClubListScreenState extends State<ClubListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClubProvider>();
    final clubs = provider.filteredClubs;
    const side = AppSizes.pagePadding;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: provider.loadClubs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 로고 + 큰 제목 + 검색창
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(side, 16, side, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ClubItLogo(height: 26),
                      const SizedBox(height: 20),
                      Text(
                        '어떤 동아리를\n찾고 있나요?',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 28,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _searchController,
                        hintText: '동아리 이름, 분야로 검색',
                        prefixIcon: Icons.search,
                        textInputAction: TextInputAction.search,
                        onChanged: provider.updateKeyword,
                      ),
                    ],
                  ),
                ),
              ),

              // 카테고리 칩 (가로 스크롤)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(side, 12, side, 4),
                    itemCount: provider.categories.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSizes.gapS),
                    itemBuilder: (context, index) {
                      final category =
                          index == 0 ? null : provider.categories[index - 1];
                      return CategoryChip(
                        label: category ?? '전체',
                        selected: provider.selectedCategory == category,
                        onTap: () => provider.selectCategory(category),
                      );
                    },
                  ),
                ),
              ),

              // '전체 동아리 N' + '모집 중만'
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(side, 12, 8, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '${provider.selectedCategory ?? '전체'} 동아리 '
                        '${clubs.length}',
                        style: AppTextStyles.label.copyWith(fontSize: 17),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        onTap: () =>
                            provider.setRecruitingOnly(!provider.recruitingOnly),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: provider.recruitingOnly,
                              onChanged: (v) =>
                                  provider.setRecruitingOnly(v ?? false),
                              activeColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.textSecondary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Text('모집 중만',
                                style: AppTextStyles.bodySecondary),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ..._buildList(provider, clubs),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(ClubProvider provider, List<Club> clubs) {
    if (provider.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.errorMessage != null || clubs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: PlaceholderView(
            icon: provider.errorMessage != null
                ? Icons.wifi_off_rounded
                : Icons.search_off_rounded,
            title: provider.errorMessage ?? '조건에 맞는 동아리가 없어요',
            message: provider.errorMessage != null
                ? '아래로 당겨서 다시 시도해 주세요.'
                : '검색어나 필터를 바꿔 보세요.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          8,
          AppSizes.pagePadding,
          24,
        ),
        sliver: SliverList.separated(
          itemCount: clubs.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.gapM),
          itemBuilder: (context, index) {
            final club = clubs[index];
            return ClubCard(
              club: club,
              isFavorite: provider.isFavorite(club.id),
              onFavoritePressed: () => toggleFavoriteWithFeedback(context, club.id),
              onTap: () => context.push(RoutePaths.clubDetail(club.id)),
            );
          },
        ),
      ),
    ];
  }
}

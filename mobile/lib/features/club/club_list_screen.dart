import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/club.dart';
import 'club_provider.dart';
import 'widgets/club_card.dart';

/// S03 동아리 목록 (홈 탭)
/// TODO(검색·필터 단계): 카테고리 칩 필터, 모집중만 보기 토글
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club-it', style: AppTextStyles.headline),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('동아리 검색', style: AppTextStyles.title),
              const SizedBox(height: AppSizes.gapL),
              AppTextField(
                controller: _searchController,
                hintText: '동아리 이름 또는 카테고리 검색',
                prefixIcon: Icons.search,
                textInputAction: TextInputAction.search,
                onChanged: provider.updateKeyword,
              ),
              const SizedBox(height: AppSizes.gapXL),
              const Text('동아리 목록', style: AppTextStyles.title),
              const SizedBox(height: AppSizes.gapM),
              Expanded(child: _buildList(provider, clubs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ClubProvider provider, List<Club> clubs) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Text(provider.errorMessage!, style: AppTextStyles.bodySecondary),
      );
    }
    if (clubs.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다.', style: AppTextStyles.bodySecondary),
      );
    }

    return ListView.separated(
      itemCount: clubs.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.gapM),
      itemBuilder: (context, index) {
        final club = clubs[index];
        return ClubCard(
          club: club,
          isFavorite: provider.isFavorite(club.id),
          onFavoritePressed: () => provider.toggleFavorite(club.id),
          onTap: () => context.push(RoutePaths.clubDetail(club.id)),
        );
      },
    );
  }
}

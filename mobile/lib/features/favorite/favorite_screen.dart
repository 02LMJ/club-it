import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/widgets/placeholder_view.dart';
import '../club/club_provider.dart';
import '../club/favorite_action.dart';
import '../club/widgets/club_card.dart';

/// S07 즐겨찾기 탭
/// 홈 탭과 같은 ClubProvider를 쓰기 때문에 별 표시가 바로 연동된다.
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClubProvider>();
    final clubs = provider.favoriteClubs;

    return Scaffold(
      appBar: AppBar(title: const Text('즐겨찾기')),
      body: clubs.isEmpty
          ? const PlaceholderView(
              icon: Icons.star_border,
              title: '즐겨찾기한 동아리가 없어요',
              message: '홈에서 별을 눌러 관심 동아리를 추가해 보세요.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: clubs.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.gapM),
              itemBuilder: (context, index) {
                final club = clubs[index];
                return ClubCard(
                  club: club,
                  isFavorite: true,
                  onFavoritePressed: () => toggleFavoriteWithFeedback(context, club.id),
                  onTap: () => context.push(RoutePaths.clubDetail(club.id)),
                );
              },
            ),
    );
  }
}

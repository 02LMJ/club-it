import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/widgets/placeholder_view.dart';
import 'club_provider.dart';

/// S04 동아리 상세 — 구조 확인용 임시 화면
/// TODO(상세 화면 단계): 동아리 헤더, [소개]/[게시판] 탭, 가입 상태별 하단 버튼
class ClubDetailScreen extends StatelessWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final int clubId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClubProvider>();
    final club = provider.findById(clubId);

    if (club == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const PlaceholderView(title: '동아리를 찾을 수 없습니다'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(club.name),
        actions: [
          IconButton(
            onPressed: () => provider.toggleFavorite(club.id),
            icon: Icon(
              provider.isFavorite(club.id) ? Icons.star : Icons.star_border,
              color: provider.isFavorite(club.id) ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: PlaceholderView(
        title: '${club.name} 상세',
        message: '${club.category} · 회원 ${club.memberCount}명\n${club.description}',
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: club.isRecruiting
                ? () => context.push(RoutePaths.clubApply(club.id))
                : null,
            child: Text(club.isRecruiting ? '가입 신청' : '모집 기간이 아닙니다'),
          ),
        ),
      ),
    );
  }
}

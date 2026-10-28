import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../data/models/club.dart';
import 'club_provider.dart';
import 'widgets/club_card.dart';

/// S03 동아리 목록 (홈 탭)
/// 9/30 기본 UI를 옮기고, 데이터·검색·즐겨찾기 상태를 ClubProvider로 분리
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
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Club-it',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '동아리 검색',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: provider.updateKeyword,
                decoration: InputDecoration(
                  hintText: '동아리 이름 또는 카테고리 검색',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '동아리 목록',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
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
      return Center(child: Text(provider.errorMessage!));
    }
    if (clubs.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.separated(
      itemCount: clubs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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

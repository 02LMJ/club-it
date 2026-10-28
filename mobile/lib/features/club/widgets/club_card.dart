import 'package:flutter/material.dart';

import '../../../data/models/club.dart';

/// 동아리 목록 카드 (9/30 기본 UI에서 분리)
/// TODO(공통 디자인 단계): 색상·글꼴을 테마로 교체, 모집중 뱃지 추가
class ClubCard extends StatelessWidget {
  const ClubCard({
    super.key,
    required this.club,
    required this.isFavorite,
    required this.onFavoritePressed,
    this.onTap,
  });

  final Club club;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEBFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.category,
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      club.summary,
                      style: const TextStyle(color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavoritePressed,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

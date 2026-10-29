import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import 'club_provider.dart';

/// 즐겨찾기 별 버튼 공통 동작 (홈·즐겨찾기·상세 화면에서 사용)
/// 서버 저장에 실패하면 별이 원래대로 돌아가고 하단에 안내가 뜬다.
Future<void> toggleFavoriteWithFeedback(BuildContext context, int clubId) async {
  final messenger = ScaffoldMessenger.of(context);
  final provider = context.read<ClubProvider>();
  try {
    await provider.toggleFavorite(clubId);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

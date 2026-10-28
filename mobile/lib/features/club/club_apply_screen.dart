import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_view.dart';

/// S05 가입 신청 — 구조 확인용 임시 화면
/// TODO(가입 신청 단계): 신청자 정보, 신청 메시지 입력, 신청하기 버튼
class ClubApplyScreen extends StatelessWidget {
  const ClubApplyScreen({super.key, required this.clubId});

  final int clubId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가입 신청')),
      body: PlaceholderView(title: '가입 신청', message: '동아리 ID: $clubId'),
    );
  }
}

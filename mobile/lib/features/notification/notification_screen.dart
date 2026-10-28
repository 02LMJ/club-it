import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_view.dart';

/// S08 알림 탭 — 구조 확인용 임시 화면
/// TODO(알림 단계): 새 게시물·가입 승인·가입 거부 알림 목록
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: const PlaceholderView(title: '알림'),
    );
  }
}

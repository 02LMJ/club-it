import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_view.dart';

/// S06 게시물 상세 — 구조 확인용 임시 화면
/// TODO(게시물 단계): 제목·작성자·본문, 댓글 목록, 하단 댓글 입력창
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시물')),
      body: PlaceholderView(title: '게시물 상세', message: '게시물 ID: $postId'),
    );
  }
}

/// 댓글 (서버 GET /posts/{id}/comments 응답)
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['comment_id'] as int,
      postId: json['post_id'] as int,
      authorId: json['user_id'] as int,
      authorName: json['author_name'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

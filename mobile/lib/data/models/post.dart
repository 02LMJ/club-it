/// 게시물 (서버 GET /clubs/{id}/posts, GET /posts/{id} 응답)
class Post {
  const Post({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    this.commentCount = 0,
  });

  final int id;
  final int clubId;
  final int authorId;
  final String authorName;

  /// RECRUIT(모집글) / NOTICE(공지사항) / PROMO(활동 홍보글)
  final String type;
  final String title;
  final String content;
  final DateTime createdAt;
  final int commentCount;

  bool get isNotice => type == 'NOTICE';

  String get typeLabel => switch (type) {
        'RECRUIT' => '모집',
        'NOTICE' => '공지',
        'PROMO' => '홍보',
        _ => '게시물',
      };

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['post_id'] as int,
      clubId: json['club_id'] as int,
      authorId: json['user_id'] as int,
      authorName: json['author_name'] as String? ?? '',
      type: json['post_type'] as String? ?? 'NOTICE',
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      commentCount: json['comment_count'] as int? ?? 0,
    );
  }
}

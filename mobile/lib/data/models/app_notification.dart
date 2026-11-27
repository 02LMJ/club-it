/// 알림 (서버 GET /notifications 응답)
/// Flutter에 이미 Notification 클래스가 있어서 이름을 AppNotification으로 씀
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.postId,
  });

  final int id;

  /// 예) "[CATS] 새 공지사항: 이번 주 스터디 공지"
  ///     "[CATS] 가입 신청이 승인되었습니다."
  final String message;

  /// 새 게시물 알림이면 게시물 번호, 가입 승인·거절 알림이면 null
  final int? postId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      message: message,
      postId: postId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['notification_id'] as int,
      message: json['message'] as String? ?? '',
      postId: json['post_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

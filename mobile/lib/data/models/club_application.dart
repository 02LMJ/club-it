/// 임원이 보는 가입 신청 한 건 (서버 GET /clubs/{id}/applications 응답)
/// 부원 목록(GET /clubs/{id}/members)도 같은 형식
class ClubApplication {
  const ClubApplication({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.role,
    required this.joinDate,
    this.message,
  });

  /// membership_id (승인·거절할 때 사용)
  final int id;
  final int userId;
  final String userName;
  final String userEmail;

  /// PENDING / APPROVED / REJECTED / CANCELED
  final String status;

  /// MEMBER / OFFICER
  final String role;

  /// 신청한 날
  final DateTime joinDate;

  /// 신청자가 쓴 지원 동기
  final String? message;

  factory ClubApplication.fromJson(Map<String, dynamic> json) {
    return ClubApplication(
      id: json['membership_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      status: json['status'] as String,
      role: json['member_role'] as String? ?? 'MEMBER',
      joinDate: DateTime.parse(json['join_date'] as String),
      message: json['message'] as String?,
    );
  }
}

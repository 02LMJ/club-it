/// 내 가입 신청·가입 현황 한 건 (서버 GET /me/memberships 응답)
class MyMembership {
  const MyMembership({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.status,
    required this.role,
    required this.joinDate,
    this.message,
    this.rejectReason,
  });

  final int id;
  final int clubId;
  final String clubName;

  /// PENDING / APPROVED / REJECTED / CANCELED
  final String status;

  /// MEMBER / OFFICER
  final String role;
  final DateTime joinDate;
  final String? message;
  final String? rejectReason;

  String get statusLabel => switch (status) {
        'PENDING' => '승인 대기',
        'APPROVED' => role == 'OFFICER' ? '임원' : '가입 완료',
        'REJECTED' => '거절됨',
        'CANCELED' => '신청 취소',
        _ => status,
      };

  factory MyMembership.fromJson(Map<String, dynamic> json) {
    return MyMembership(
      id: json['membership_id'] as int,
      clubId: json['club_id'] as int,
      clubName: json['club_name'] as String? ?? '',
      status: json['status'] as String,
      role: json['member_role'] as String? ?? 'MEMBER',
      joinDate: DateTime.parse(json['join_date'] as String),
      message: json['message'] as String?,
      rejectReason: json['reject_reason'] as String?,
    );
  }
}

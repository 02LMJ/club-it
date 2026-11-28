/// 로그인한 사용자 정보 (서버 GET /auth/me 응답)
class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final int id;
  final String email;
  final String name;

  /// STUDENT / OFFICER(동아리 등록 권한) / ADMIN
  final String role;

  bool get isAdmin => role == 'ADMIN';

  /// 새 동아리를 등록할 수 있는지 (관리자가 OFFICER 권한을 준 사용자, 또는 관리자)
  bool get canCreateClub => role == 'OFFICER' || role == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'STUDENT',
    );
  }
}

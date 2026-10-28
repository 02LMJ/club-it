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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'STUDENT',
    );
  }
}

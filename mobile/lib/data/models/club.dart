/// 동아리 정보 모델 (서버 GET /clubs 응답, DB: club 테이블)
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.isRecruiting,
    required this.memberCount,
    this.isFavorite = false,
    this.myStatus,
    this.myRole,
  });

  final int id;
  final String name;

  /// 학술 / 봉사 / 예술 / 체육 / 종교 / 취미 / 기타
  final String category;

  /// 동아리 소개 (카드에는 앞부분 2줄, 상세 [소개] 탭에는 전체)
  final String description;

  final bool isRecruiting;

  /// 승인된 멤버 수 (임원 포함)
  final int memberCount;

  /// 로그인한 사용자가 즐겨찾기했는지
  final bool isFavorite;

  /// 내 가입 상태: null / PENDING / APPROVED / REJECTED / CANCELED
  final String? myStatus;

  /// 내 역할: OFFICER면 임원 메뉴 표시
  final String? myRole;

  /// 한 줄 소개: 소개글의 첫 줄
  String get summary => description.split('\n').first.trim();

  bool get isOfficer => myRole == 'OFFICER';

  /// 서버 JSON(snake_case) → Club
  factory Club.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] as String?)?.trim() ?? '';
    return Club(
      id: json['club_id'] as int,
      name: json['club_name'] as String,
      category: category.isEmpty ? '기타' : category,
      description: json['description'] as String? ?? '',
      isRecruiting: json['recruit_status'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      myStatus: json['my_status'] as String?,
      myRole: json['my_role'] as String?,
    );
  }
}

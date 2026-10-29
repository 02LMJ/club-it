/// 동아리 정보 모델 (DB: CLUB 테이블)
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.description,
    required this.isRecruiting,
    required this.memberCount,
    this.isFavorite = false,
    this.myStatus,
    this.myRole,
  });

  final int id;
  final String name;

  /// 학술 / 예술 / 체육 / 봉사 / 종교 / 취미 / 기타
  final String category;

  /// 목록 카드에 보여줄 한 줄 소개
  final String summary;

  /// 상세 화면 [소개] 탭에 보여줄 전체 소개
  final String description;

  final bool isRecruiting;
  final int memberCount;

  /// 아래 3개는 로그인 토큰을 보내서 조회했을 때만 의미가 있음
  /// 내가 즐겨찾기한 동아리인지
  final bool isFavorite;

  /// 내 가입 상태: PENDING / APPROVED / REJECTED / CANCELED / null(신청 안 함)
  /// → 상세 화면 하단 버튼 결정 (docs/app-server-flow.md 2번 표)
  final String? myStatus;

  /// 가입 승인된 경우 내 역할: OFFICER / MEMBER (OFFICER면 임원 메뉴 표시)
  final String? myRole;

  bool get isOfficer => myRole == 'OFFICER';

  /// 서버 응답(GET /clubs, GET /clubs/{id})을 Club 객체로 변환
  /// 서버 필드 이름: docs/app-server-flow.md 5번 표
  factory Club.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String? ?? '';
    return Club(
      id: json['club_id'] as int,
      name: json['club_name'] as String,
      category: json['category'] as String? ?? '기타',
      // 서버에 한 줄 소개 필드가 없어서 소개글의 첫 줄을 사용
      summary: description.split('\n').first.trim(),
      description: description,
      isRecruiting: json['recruit_status'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      myStatus: json['my_status'] as String?,
      myRole: json['my_role'] as String?,
    );
  }
}

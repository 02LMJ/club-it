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

  /// 서버 API 응답(JSON)을 Club 객체로 변환 — 서버 연동 시 사용
  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isRecruiting: json['isRecruiting'] as bool? ?? false,
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }
}

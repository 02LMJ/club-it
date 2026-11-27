import '../../core/network/api_client.dart';

/// LLM 작성 보조 작업 종류 (서버 task 값)
enum AiTask {
  title('title', '제목 추천'),
  draft('draft', '초안 만들기'),
  improve('improve', '문장 다듬기'),
  summary('summary', '요약하기');

  const AiTask(this.value, this.label);

  final String value;
  final String label;
}

/// LLM 작성 보조 결과
class AiResult {
  const AiResult({
    required this.text,
    this.suggestions = const [],
    this.provider = 'mock',
  });

  /// 본문 초안·다듬은 문장·요약 결과
  final String text;

  /// 제목 추천일 때 제목 후보 목록
  final List<String> suggestions;

  /// 서버가 쓴 LLM (mock이면 API 키 없이 돌려주는 예시 응답)
  final String provider;

  bool get isMock => provider == 'mock';

  factory AiResult.fromJson(Map<String, dynamic> json) {
    return AiResult(
      text: json['result'] as String? ?? '',
      suggestions: (json['suggestions'] as List? ?? const [])
          .map((e) => e as String)
          .where((e) => e.isNotEmpty)
          .toList(),
      provider: json['provider'] as String? ?? 'mock',
    );
  }
}

/// LLM 작성 보조 요청 (POST /ai/assist)
abstract class AiRepository {
  /// [text] 초안: 키워드·메모 / 제목 추천·다듬기·요약: 대상 본문
  Future<AiResult> assist({
    required AiTask task,
    required String postType,
    required String text,
    int? clubId,
  });
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiAiRepository implements AiRepository {
  ApiAiRepository(this._api);

  final ApiClient _api;

  @override
  Future<AiResult> assist({
    required AiTask task,
    required String postType,
    required String text,
    int? clubId,
  }) async {
    final data = await _api.post('/ai/assist', body: {
      'task': task.value,
      'post_type': postType,
      'text': text,
      if (clubId != null) 'club_id': clubId,
    });
    return AiResult.fromJson(data as Map<String, dynamic>);
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockAiRepository implements AiRepository {
  @override
  Future<AiResult> assist({
    required AiTask task,
    required String postType,
    required String text,
    int? clubId,
  }) async {
    return switch (task) {
      AiTask.title => const AiResult(
          text: '',
          suggestions: ['함께할 신입 부원을 모집합니다', '초보도 환영! 신입 모집 안내'],
        ),
      AiTask.draft => const AiResult(text: '[예시 초안] 신입 부원을 모집합니다.'),
      AiTask.improve => AiResult(text: '[다듬은 글] $text'),
      AiTask.summary => const AiResult(text: '[예시 요약] 신입 부원 모집 안내입니다.'),
    };
  }
}

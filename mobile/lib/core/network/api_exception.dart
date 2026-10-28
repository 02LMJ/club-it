/// 서버 요청 실패. [message]는 화면에 그대로 보여줄 수 있는 한글 문장이다.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;

  /// 서버가 응답한 상태 코드. 서버에 연결조차 못 했으면 null.
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

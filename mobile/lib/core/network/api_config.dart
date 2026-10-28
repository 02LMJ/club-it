import 'package:flutter/foundation.dart';

/// 서버 주소 설정 (docs/app-server-flow.md 공통 규칙)
///
/// - 웹·윈도우: http://localhost:8001
/// - 안드로이드 에뮬레이터: http://10.0.2.2:8001
/// - 실제 폰 등 다른 주소: flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8001
class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://localhost:8001';
  }

  static const timeout = Duration(seconds: 10);
}

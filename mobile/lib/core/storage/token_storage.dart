import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 토큰을 기기에 저장 (앱을 껐다 켜도 유지 → 자동 로그인)
class TokenStorage {
  static const _key = 'access_token';

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_key);
    _loaded = true;
    return _cached;
  }

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    _cached = token;
    _loaded = true;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
    _loaded = true;
  }
}

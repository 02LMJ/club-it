import '../../core/network/api_client.dart';
import '../models/user.dart';

/// 회원가입·로그인 관련 서버 요청
abstract class AuthRepository {
  /// 로그인 성공 시 access_token 반환
  Future<String> login({required String email, required String password});

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  });

  Future<User> fetchMe();
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return (data as Map<String, dynamic>)['access_token'] as String;
  }

  @override
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/auth/signup',
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  @override
  Future<User> fetchMe() async {
    final data = await _api.get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }
}

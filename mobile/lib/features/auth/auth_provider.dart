import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

/// 로그인 상태 관리.
/// GoRouter가 이 객체를 구독(refreshListenable)하고 있어서,
/// 로그인/로그아웃 시 자동으로 화면이 이동한다.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._tokenStorage);

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// 앱 시작 시: 저장된 토큰이 있으면 서버에 확인해서 자동 로그인
  Future<void> restore() async {
    final token = await _tokenStorage.read();
    if (token == null) return;
    try {
      _user = await _repository.fetchMe().timeout(const Duration(seconds: 3));
    } on ApiException catch (e) {
      // 토큰 만료·잘못된 토큰이면 삭제. 서버가 꺼진 경우에는 토큰을 남겨둔다.
      if (e.isUnauthorized) await _tokenStorage.clear();
    } on TimeoutException {
      // 서버 응답 없음 → 로그인 화면부터 시작
    }
    notifyListeners();
  }

  /// 실패하면 [ApiException]을 던진다 (화면에서 메시지 표시).
  Future<void> login({required String email, required String password}) async {
    final token = await _repository.login(
      email: email.trim(),
      password: password,
    );
    await _tokenStorage.save(token);
    try {
      _user = await _repository.fetchMe();
    } catch (_) {
      await _tokenStorage.clear();
      rethrow;
    }
    notifyListeners();
  }

  /// 회원가입 후 바로 로그인까지 진행
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await _repository.signup(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _user = null;
    notifyListeners();
  }

  /// 사용 중 서버가 401(토큰 만료)을 보냈을 때 ApiClient가 호출
  void handleUnauthorized() {
    if (_user == null) return;
    logout();
  }
}

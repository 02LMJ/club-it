import 'package:flutter/foundation.dart';

/// 로그인 상태 관리.
/// GoRouter가 이 객체를 구독(refreshListenable)하고 있어서,
/// 로그인/로그아웃 시 자동으로 화면이 이동한다.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// TODO(로그인 구현 단계): 서버 로그인 API 호출, 토큰 저장
  Future<void> login({required String email, required String password}) async {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

/// 화면 주소 모음. 주소 문자열을 직접 쓰지 말고 여기 있는 값을 사용한다.
class RoutePaths {
  RoutePaths._();

  // 인증
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';

  // 하단 탭 4개
  static const home = '/';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const my = '/my';

  // 상세 화면 (하단 탭 없이 전체 화면으로 열림)
  static String clubDetail(int clubId) => '/clubs/$clubId';
  static String clubApply(int clubId) => '/clubs/$clubId/apply';
  static String postDetail(int postId) => '/posts/$postId';

  // 개발용
  static const designPreview = '/dev/design';
}

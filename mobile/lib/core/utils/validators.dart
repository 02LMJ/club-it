/// 입력값 검사 함수 모음 (서버 규칙과 동일하게 맞춤)
/// 문제가 있으면 오류 문구를, 없으면 null을 반환한다.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailPattern.hasMatch(v)) return '이메일 형식이 올바르지 않습니다.';
    return null;
  }

  /// 로그인용: 비어 있는지만 확인
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
    return null;
  }

  /// 회원가입용: 8자 이상 64자 이하
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력해주세요.';
    if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (v.length > 64) return '비밀번호는 64자 이하여야 합니다.';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return '비밀번호를 한 번 더 입력해주세요.';
      if (value != original()) return '비밀번호가 일치하지 않습니다.';
      return null;
    };
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이름을 입력해주세요.';
    if (v.length > 50) return '이름은 50자 이하여야 합니다.';
    return null;
  }
}

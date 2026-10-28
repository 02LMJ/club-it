import 'package:flutter/material.dart';

/// Club-it 색상 모음 — '차콜 · 아이보리' 시안 (2026-10 팀 확정)
/// 화면에서 Color(0xFF...)를 직접 쓰지 말고 여기 값을 사용한다.
class AppColors {
  AppColors._();

  // 브랜드
  /// 차콜: 주요 버튼, 선택된 칩, '모집 중' 뱃지, 로고
  static const primary = Color(0xFF2A2925);

  /// 차콜 위의 아주 옅은 배경 (하단 탭 선택 표시 등)
  static const primaryLight = Color(0xFFECE6DE);

  /// 캐러멜: 로고 점, 즐겨찾기 별 등 포인트
  static const accent = Color(0xFFB0703A);

  // 배경
  static const background = Color(0xFFF7F3ED); // 아이보리 (홈 등 기본 배경)
  static const startBackground = Color(0xFFF0EAE3); // 시작 화면 배경
  static const surface = Color(0xFFFFFEFA); // 카드, 입력창, 하단 탭
  static const border = Color(0xFFE8E2DA);
  static const tagBackground = Color(0xFFF1EDE9); // 카테고리 태그

  // 보조 버튼 (시작 화면 '회원가입')
  static const secondaryButton = Color(0xFFFBF7F4);
  static const secondaryButtonBorder = Color(0xFFDAD4CF);

  // 글자
  static const textPrimary = Color(0xFF1F1D1A);
  static const textSecondary = Color(0xFF6B6660);
  static const textHint = Color(0xFFA39E97);

  // 상태
  static const favorite = accent;
  static const recruiting = Color(0xFFFFFEFA); // '모집 중' 글자 (차콜 배경 위)
  static const recruitingBackground = primary;
  static const closed = Color(0xFF8E8A84); // '모집 마감' 글자
  static const closedBackground = tagBackground;
  static const error = Color(0xFFD1463E);
}

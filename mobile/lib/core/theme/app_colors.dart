import 'package:flutter/material.dart';

/// Club-it 색상 모음. 화면에서 Color(0xFF...)를 직접 쓰지 말고 여기 값을 사용한다.
class AppColors {
  AppColors._();

  // 브랜드
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFFECEBFF);

  // 배경
  static const background = Color(0xFFF7F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E6EC);

  // 글자
  static const textPrimary = Color(0xFF1C1B22);
  static const textSecondary = Color(0xFF6E6D7A);
  static const textHint = Color(0xFFA3A2AE);

  // 상태
  static const favorite = Color(0xFFFFC107);
  static const recruiting = Color(0xFF1E9E5A);
  static const recruitingBackground = Color(0xFFE6F6ED);
  static const closed = Color(0xFF8E8D99);
  static const closedBackground = Color(0xFFEFEFF3);
  static const error = Color(0xFFE5484D);
}

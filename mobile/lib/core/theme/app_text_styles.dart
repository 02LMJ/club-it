import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Club-it 글자 스타일 모음
class AppTextStyles {
  AppTextStyles._();

  /// pubspec.yaml에 Pretendard 폰트를 등록하면 적용되고,
  /// 등록 전에는 기본 글꼴로 자동 대체된다.
  static const fontFamily = 'Pretendard';

  /// 화면 대제목 (예: 앱바 'Club-it')
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 섹션 제목 (예: '동아리 검색')
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 카드 제목 (예: 동아리명)
  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 본문
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 보조 설명 (예: 한 줄 소개)
  static const bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// 버튼, 입력창 라벨
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 뱃지, 카테고리, 작은 정보
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

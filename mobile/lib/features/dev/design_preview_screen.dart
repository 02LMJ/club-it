import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/club_it_logo.dart';

/// 개발용: 공통 디자인 요소(색상·글꼴·위젯)를 한 화면에서 확인
/// 마이 탭 > '디자인 미리보기 (개발용)'에서 열 수 있다.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  String _selectedCategory = '전체';
  bool _loading = false;

  static const _categories = ['전체', '학술', '예술', '체육', '봉사'];

  static const _colors = <String, Color>{
    'primary': AppColors.primary,
    'accent': AppColors.accent,
    'background': AppColors.background,
    'startBg': AppColors.startBackground,
    'surface': AppColors.surface,
    'tag': AppColors.tagBackground,
    'border': AppColors.border,
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'error': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('디자인 미리보기')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          _section('색상'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in _colors.entries)
                Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: entry.value,
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.key, style: AppTextStyles.caption),
                  ],
                ),
            ],
          ),

          _section('글자'),
          const Text('Headline 24 Bold', style: AppTextStyles.headline),
          const Text('Title 20 Bold', style: AppTextStyles.title),
          const Text('Subtitle 18 Bold', style: AppTextStyles.subtitle),
          const Text('Body 15 Regular 본문입니다', style: AppTextStyles.body),
          const Text('BodySecondary 14 보조 설명',
              style: AppTextStyles.bodySecondary),
          const Text('Label 15 SemiBold', style: AppTextStyles.label),
          const Text('Caption 13 Medium', style: AppTextStyles.caption),

          _section('버튼'),
          AppButton(label: '기본 버튼', onPressed: () {}),
          const SizedBox(height: AppSizes.gapM),
          AppButton(
            label: '테두리 버튼',
            variant: AppButtonVariant.outlined,
            onPressed: () {},
          ),
          const SizedBox(height: AppSizes.gapM),
          AppButton(
            label: '아이콘 버튼',
            icon: Icons.edit_outlined,
            onPressed: () {},
          ),
          const SizedBox(height: AppSizes.gapM),
          AppButton(
            label: '눌러서 로딩 확인',
            isLoading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _loading = false);
            },
          ),
          const SizedBox(height: AppSizes.gapM),
          const AppButton(label: '비활성화 버튼', onPressed: null),
          const SizedBox(height: AppSizes.gapS),
          AppButton(
            label: '텍스트 버튼',
            variant: AppButtonVariant.text,
            onPressed: () {},
          ),

          _section('입력창'),
          const AppTextField(label: '이메일', hintText: 'example@cbnu.ac.kr'),
          const SizedBox(height: AppSizes.gapL),
          const AppTextField(
            label: '비밀번호',
            hintText: '8자 이상',
            obscureText: true,
          ),
          const SizedBox(height: AppSizes.gapL),
          const AppTextField(
            label: '오류 상태',
            hintText: '이메일',
            errorText: '이메일 형식이 올바르지 않습니다.',
          ),
          const SizedBox(height: AppSizes.gapL),
          const AppTextField(
            hintText: '동아리 이름 또는 카테고리 검색',
            prefixIcon: Icons.search,
          ),

          _section('카테고리 칩'),
          Wrap(
            spacing: 8,
            children: [
              for (final category in _categories)
                CategoryChip(
                  label: category,
                  selected: category == _selectedCategory,
                  onTap: () => setState(() => _selectedCategory = category),
                ),
            ],
          ),

          _section('로고'),
          const Row(
            children: [
              ClubItSymbol(size: 56),
              SizedBox(width: 24),
              ClubItLogo(height: 28),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          const ClubItWordmark(fontSize: 44),

          _section('뱃지'),
          Wrap(
            spacing: 8,
            children: [
              AppBadge.category('학술'),
              AppBadge.recruiting(true),
              AppBadge.recruiting(false),
              AppBadge.notice(),
            ],
          ),

          _section('카드'),
          AppCard(
            onTap: () {},
            child: const Text('누르면 물결 효과가 나는 공통 카드',
                style: AppTextStyles.body),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.gapXL, bottom: AppSizes.gapM),
      child: Text(title, style: AppTextStyles.title),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import 'auth_provider.dart';

/// S01 로그인 — 구조 확인용 임시 화면
/// TODO(로그인 구현 단계): 이메일·비밀번호 입력창, 입력값 검증, 서버 로그인 연동
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Club-it',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              const Text(
                'Find Your Club, Build Your Community',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 48),
              AppButton(
                label: '로그인 (임시)',
                // 임시: 누르면 바로 로그인 처리 → router가 홈으로 이동시킴
                onPressed: () => context
                    .read<AuthProvider>()
                    .login(email: 'test@cbnu.ac.kr', password: 'temp'),
              ),
              const SizedBox(height: AppSizes.gapM),
              AppButton(
                label: '회원가입',
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(RoutePaths.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

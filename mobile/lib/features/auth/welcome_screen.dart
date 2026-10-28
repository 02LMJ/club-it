import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/club_it_logo.dart';

/// S00 시작 화면 — 로그인하지 않았을 때 가장 먼저 보이는 화면
/// 로고 / 'club·it' / '우리 학교 동아리, 한 곳에서' / 로그인·회원가입
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.startBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const ClubItSymbol(size: 112),
                  const SizedBox(height: 36),
                  const ClubItWordmark(fontSize: 60),
                  const SizedBox(height: 20),
                  Text(
                    '우리 학교 동아리, 한 곳에서',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 4),
                  AppButton(
                    label: '로그인',
                    onPressed: () => context.push(RoutePaths.login),
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
        ),
      ),
    );
  }
}

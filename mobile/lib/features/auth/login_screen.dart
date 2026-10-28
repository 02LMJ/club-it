import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_paths.dart';
import 'auth_provider.dart';

/// S01 로그인 — 구조 확인용 임시 화면
/// TODO(로그인 구현 단계): 이메일·비밀번호 입력창, 입력값 검증, 계정 찾기
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Club-it',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find Your Club, Build Your Community',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 48),
              FilledButton(
                // 임시: 누르면 바로 로그인 처리 → router가 홈으로 이동시킴
                onPressed: () => context
                    .read<AuthProvider>()
                    .login(email: 'test@cbnu.ac.kr', password: 'temp'),
                child: const Text('로그인 (임시)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.signup),
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

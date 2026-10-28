import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_view.dart';

/// S02 회원가입 — 구조 확인용 임시 화면
/// TODO(회원가입 구현 단계): 이름·학번·학과·이메일·비밀번호 입력 및 검증
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: const PlaceholderView(title: '회원가입'),
    );
  }
}

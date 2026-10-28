import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_banner.dart';
import 'auth_provider.dart';

/// S02 회원가입 (이름·이메일·비밀번호 — 서버 DB 기준)
/// 가입에 성공하면 바로 로그인되고, router가 홈으로 이동시킨다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    // 화면이 바뀐 뒤에도 알림을 띄울 수 있도록 미리 가져둠
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().signup(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었어요. 환영합니다!')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '알 수 없는 오류가 발생했어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: '이름',
                      hintText: '홍길동',
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    AppTextField(
                      controller: _emailController,
                      label: '이메일',
                      hintText: 'example@cbnu.ac.kr',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    AppTextField(
                      controller: _passwordController,
                      label: '비밀번호',
                      hintText: '8자 이상',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.newPassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    AppTextField(
                      controller: _confirmController,
                      label: '비밀번호 확인',
                      hintText: '비밀번호를 한 번 더 입력',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: Validators.confirmPassword(
                        () => _passwordController.text,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.gapXL),
                    if (_errorMessage != null) ...[
                      ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppSizes.gapM),
                    ],
                    AppButton(
                      label: '가입하기',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

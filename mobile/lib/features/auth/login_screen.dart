import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/club_it_logo.dart';
import '../../core/widgets/error_banner.dart';
import 'auth_provider.dart';

/// S01 로그인
/// 성공하면 AuthProvider가 상태를 바꾸고, router가 홈으로 이동시킨다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  /// 버튼을 한 번 누른 뒤부터 입력할 때마다 검사
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text,
            password: _passwordController.text,
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
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: ClubItSymbol(size: 52),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '다시 만나서 반가워요',
                      style: AppTextStyles.headline.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    const Text(
                      '학교 이메일로 로그인해 주세요.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 36),
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
                      hintText: '비밀번호를 입력하세요',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: Validators.loginPassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.gapXL),
                    if (_errorMessage != null) ...[
                      ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppSizes.gapM),
                    ],
                    AppButton(
                      label: '로그인',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('아직 계정이 없나요?',
                            style: AppTextStyles.bodySecondary),
                        AppButton(
                          label: '회원가입',
                          variant: AppButtonVariant.text,
                          fullWidth: false,
                          onPressed: _isLoading
                              ? null
                              : () => context.push(RoutePaths.signup),
                        ),
                      ],
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

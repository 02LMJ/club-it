import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outlined, text }

/// Club-it 공통 버튼
///
/// ```dart
/// AppButton(label: '로그인', onPressed: _login)
/// AppButton(label: '회원가입', variant: AppButtonVariant.outlined, onPressed: ...)
/// AppButton(label: '로그인', isLoading: true, onPressed: _login) // 로딩 중
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;

  /// null이면 비활성화(회색) 버튼
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// true면 글자 대신 로딩 표시, 버튼 비활성화 (중복 클릭 방지)
  final bool isLoading;

  /// true면 가로 전체 너비
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget child;
    if (isLoading) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      child = Text(label);
    }

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.outlined =>
        OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.text =>
        TextButton(onPressed: effectiveOnPressed, child: child),
    };

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

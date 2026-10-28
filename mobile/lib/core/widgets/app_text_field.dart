import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Club-it 공통 입력창
///
/// ```dart
/// AppTextField(label: '이메일', hintText: 'example@cbnu.ac.kr', controller: _email)
/// AppTextField(label: '비밀번호', obscureText: true, controller: _pw) // 눈 아이콘 자동
/// AppTextField(hintText: '검색', prefixIcon: Icons.search, onChanged: ...)
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  final TextEditingController? controller;

  /// 입력창 위에 표시되는 제목
  final String? label;
  final String? hintText;

  /// 입력창 아래 빨간 오류 문구 (null이면 표시 안 함)
  final String? errorText;
  final IconData? prefixIcon;

  /// true면 비밀번호처럼 가리고, 오른쪽에 보기/숨기기 아이콘 표시
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Form 안에서 쓸 때 입력값 검사 함수 (문제가 있으면 오류 문구 반환)
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon:
            widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: AppTextStyles.label),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

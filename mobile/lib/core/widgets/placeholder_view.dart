import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 아직 구현하지 않은 화면 또는 빈 목록에 보여주는 안내
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.construction,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.subtitle),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

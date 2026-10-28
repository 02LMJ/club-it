import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

/// Club-it 공통 카드 (흰 배경, 둥근 모서리, 누르면 물결 효과)
///
/// ```dart
/// AppCard(onTap: () => ..., child: Text('내용'))
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSizes.cardPadding),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

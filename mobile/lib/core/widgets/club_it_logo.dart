import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Club-it 'C' 심볼: 오른쪽이 열린 두꺼운 C + 캐러멜 점
///
/// ```dart
/// const ClubItSymbol(size: 120)
/// ```
class ClubItSymbol extends StatelessWidget {
  const ClubItSymbol({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _SymbolPainter()),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.19;
    final radius = (s - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // C: 오른쪽 약 80도가 열린 원호, 끝은 둥글게
    const gap = 80 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      gap / 2,
      2 * math.pi - gap,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // 캐러멜 점: C가 열린 쪽 가운데
    canvas.drawCircle(
      center + Offset(radius * 0.95, 0),
      s * 0.12,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 'club·it' 글자 로고 (가운데 점은 캐러멜)
class ClubItWordmark extends StatelessWidget {
  const ClubItWordmark({super.key, this.fontSize = 24});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.headline.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      letterSpacing: -fontSize * 0.04,
      height: 1,
    );
    final dot = fontSize * 0.2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('club', style: style),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.06),
          child: Container(
            width: dot,
            height: dot,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Text('it', style: style),
      ],
    );
  }
}

/// 심볼 + 글자 로고를 가로로 배치 (홈 상단)
class ClubItLogo extends StatelessWidget {
  const ClubItLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubItSymbol(size: height),
        SizedBox(width: height * 0.3),
        ClubItWordmark(fontSize: height * 0.95),
      ],
    );
  }
}

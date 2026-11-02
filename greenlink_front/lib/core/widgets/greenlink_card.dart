// 공통 카드 위젯

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// GreenlinkCard — 카드 위젯
class GreenlinkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const GreenlinkCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 18.0,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.surfaceCard;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0,0,0,0.04)
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primarySoft.withValues(alpha: 0.5),
          highlightColor: AppColors.canvasGreenTint.withValues(alpha: 0.5),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

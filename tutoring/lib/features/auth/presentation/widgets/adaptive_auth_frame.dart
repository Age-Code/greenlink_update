import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

/// Keeps the mobile auth composition readable on wide viewports: on tablet
/// and desktop the screen sits in a centered phone-sized card (430 wide, at
/// most 844 tall) instead of stretching to the full window height.
class AdaptiveAuthFrame extends StatelessWidget {
  const AdaptiveAuthFrame({super.key, required this.child});

  final Widget child;

  static const cardWidth = 430.0;
  static const cardMaxHeight = 844.0;
  static const frameInset = 32.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppBreakpoints.of(constraints.maxWidth) == ScreenType.mobile) {
          return child;
        }
        final height = math.min(
          cardMaxHeight,
          math.max(0, constraints.maxHeight - frameInset * 2),
        );
        return ColoredBox(
          color: AppColors.softGray,
          child: Center(
            child: Container(
              width: cardWidth,
              height: height.toDouble(),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1F1A17),
                    offset: Offset(0, 18),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

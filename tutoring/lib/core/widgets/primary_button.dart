import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
    this.isLoading = false,
    this.icon,
    this.iconLeading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool isLoading;

  /// Optional icon, trailing by default (an arrow on "다음 문제") or leading
  /// when [iconLeading] is true (a plus on "새 노트 작성").
  final IconData? icon;
  final bool iconLeading;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<StudyTogetherTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.field),
        boxShadow: onPressed == null ? null : tokens.ctaShadow,
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.55),
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : icon == null
                  ? Text(label)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconLeading) ...[
                          Icon(icon, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(label),
                        if (!iconLeading) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 18),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

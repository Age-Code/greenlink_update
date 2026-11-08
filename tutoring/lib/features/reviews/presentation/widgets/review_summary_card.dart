import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';

/// "다시 확인할 내용이 N개 있어요" panel with the start button. The button
/// sits to the right on tablet and desktop and drops below on mobile.
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    super.key,
    required this.pendingCount,
    required this.onStart,
  });

  final int pendingCount;

  /// Null when nothing is pending; the button is then disabled.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final stacked = context.screenType == ScreenType.mobile;
    final headline = Row(
      children: [
        Flexible(
          child: Text(
            pendingCount == 0
                ? '다시 확인할 내용을 모두 확인했어요.'
                : '다시 확인할 내용이 $pendingCount개 있어요.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.45,
              height: 1.5,
            ),
          ),
        ),
        if (pendingCount > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$pendingCount',
              style: const TextStyle(
                color: AppColors.coralDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
    final button = FilledButton.icon(
      onPressed: onStart,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.45),
        disabledForegroundColor: AppColors.surface,
        minimumSize: const Size(0, AppLayout.minTouchHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Icons.auto_stories_outlined, size: 18),
      label: const Text('복습 시작하기'),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child:
          stacked
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [headline, const SizedBox(height: AppSpacing.md), button],
              )
              : Row(
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: AppSpacing.md),
                  button,
                ],
              ),
    );
  }
}

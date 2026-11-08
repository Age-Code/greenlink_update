import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';

/// Visual state of one answer option (09_Quiz_Feedback).
enum QuizOptionState {
  /// Not chosen, answer not checked yet.
  idle,

  /// Chosen, answer not checked yet.
  selected,

  /// Chosen and wrong ("내 답").
  wrong,

  /// The correct option after checking ("정답").
  correct,

  /// Neither chosen nor correct after checking.
  muted,
}

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.index,
    required this.label,
    required this.state,
    required this.onTap,
  });

  /// Zero-based; shown as 1–4.
  final int index;
  final String label;
  final QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (background, border, borderWidth) = switch (state) {
      QuizOptionState.idle => (AppColors.surface, AppColors.border, 1.0),
      QuizOptionState.selected => (
        AppColors.noteHighlight,
        AppColors.coral,
        1.0,
      ),
      QuizOptionState.wrong => (
        AppColors.coralSoft,
        AppColors.coral.withValues(alpha: 0.6),
        1.0,
      ),
      QuizOptionState.correct => (
        AppColors.homeSage,
        AppColors.homeSageDark,
        2.0,
      ),
      QuizOptionState.muted => (AppColors.surface, AppColors.border, 1.0),
    };
    final muted = state == QuizOptionState.muted;
    final labelStyle = TextStyle(
      color: muted ? AppColors.textSecondary : AppColors.textPrimary,
      fontSize: 15,
      height: 1.4,
      fontWeight:
          state == QuizOptionState.correct ? FontWeight.w700 : FontWeight.w400,
    );

    return Opacity(
      opacity: muted ? 0.8 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: borderWidth),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.softGray,
          mouseCursor:
              onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTouchHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _NumberBadge(number: index + 1, state: state),
                  const SizedBox(width: 12),
                  Expanded(child: InlineCodeText(label, style: labelStyle)),
                  if (state == QuizOptionState.wrong) ...[
                    const SizedBox(width: 12),
                    const _StateChip(
                      label: '내 답',
                      background: AppColors.homePeach,
                      foreground: AppColors.coralDark,
                    ),
                  ],
                  if (state == QuizOptionState.correct) ...[
                    const SizedBox(width: 12),
                    const _StateChip(
                      label: '정답',
                      background: AppColors.sage,
                      foreground: AppColors.homeSageDark,
                      icon: Icons.check,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.state});

  final int number;
  final QuizOptionState state;

  @override
  Widget build(BuildContext context) {
    final filled = state == QuizOptionState.correct;
    final accent =
        state == QuizOptionState.wrong || state == QuizOptionState.selected;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.homeSageDark : null,
        border:
            filled
                ? null
                : Border.all(
                  color: accent ? AppColors.coral : AppColors.border,
                ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color:
              filled
                  ? AppColors.surface
                  : accent
                  ? AppColors.homeBrown
                  : AppColors.textSecondary,
          fontSize: 11,
          height: 1,
          fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 3),
          Icon(icon, size: 11, color: foreground),
        ],
      ],
    ),
  );
}

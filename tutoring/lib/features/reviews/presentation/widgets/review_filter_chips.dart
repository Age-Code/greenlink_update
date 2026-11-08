import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_filter.dart';

/// "전체 (n) / 복습 필요 (n) / 다시 확인함 (n)" chips. The row scrolls sideways
/// when it does not fit, which only happens on narrow phones.
class ReviewFilterChips extends StatelessWidget {
  const ReviewFilterChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<ReviewItem> items;
  final ReviewFilter selected;
  final ValueChanged<ReviewFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        for (final filter in ReviewFilter.values) ...[
          if (filter != ReviewFilter.values.first)
            const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: filter.chipLabel(items),
            selected: filter == selected,
            onTap: () => onChanged(filter),
          ),
        ],
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const StadiumBorder(),
    hoverColor: AppColors.softGray,
    mouseCursor: SystemMouseCursors.click,
    child: SizedBox(
      height: AppLayout.minTouchHeight,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.surface : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';

/// Divided list of review items inside one rounded card.
class ReviewListCard extends StatelessWidget {
  const ReviewListCard({super.key, required this.items, required this.onTap});

  final List<ReviewItem> items;
  final ValueChanged<ReviewItem> onTap;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.border),
          ReviewRow(item: items[index], onTap: () => onTap(items[index])),
        ],
      ],
    ),
  );
}

/// One row: colored spine, topic, prompt, status chip, chevron. Reviewed
/// rows are dimmed so pending ones stand out.
class ReviewRow extends StatelessWidget {
  const ReviewRow({super.key, required this.item, required this.onTap});

  final ReviewItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending = item.needsReview;
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.topic.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: pending ? AppColors.homeBrown : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: pending ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: pending ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 16,
            height: 1.5,
            fontWeight: pending ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
    return Material(
      color:
          pending
              ? Colors.transparent
              : AppColors.softGray.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.softGray,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  color: pending ? AppColors.homePeach : AppColors.sage,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: pending ? texts : Opacity(opacity: 0.7, child: texts),
              ),
              const SizedBox(width: AppSpacing.md),
              _StatusChip(pending: pending),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: pending ? AppColors.coralSoft : AppColors.sage,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      pending ? '복습 필요' : '다시 확인함',
      style: TextStyle(
        color: pending ? AppColors.coralDark : AppColors.sageDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

/// Filter chips of the class review list (10_Class_Review).
enum ReviewFilter {
  all('전체'),
  needsReview('복습 필요'),
  reviewed('다시 확인함');

  const ReviewFilter(this.label);

  final String label;

  List<ReviewItem> apply(List<ReviewItem> items) => switch (this) {
    ReviewFilter.all => items,
    ReviewFilter.needsReview =>
      items
          .where((item) => item.status == ReviewStatus.needsReview)
          .toList(growable: false),
    ReviewFilter.reviewed =>
      items
          .where((item) => item.status == ReviewStatus.reviewed)
          .toList(growable: false),
  };

  int count(List<ReviewItem> items) => apply(items).length;

  String chipLabel(List<ReviewItem> items) => '$label (${count(items)})';
}

/// List order: items that still need review first, newest change first.
List<ReviewItem> orderReviews(Iterable<ReviewItem> items) =>
    items.toList(growable: true)..sort((a, b) {
      if (a.needsReview != b.needsReview) return a.needsReview ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

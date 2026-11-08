/// Lifecycle of a review item. This enum is the only place that knows the
/// stored string values.
enum ReviewStatus {
  needsReview('needsReview'),
  reviewed('reviewed');

  const ReviewStatus(this.firestoreValue);

  final String firestoreValue;

  static ReviewStatus fromFirestore(String? value) =>
      value == ReviewStatus.reviewed.firestoreValue
          ? ReviewStatus.reviewed
          : ReviewStatus.needsReview;
}

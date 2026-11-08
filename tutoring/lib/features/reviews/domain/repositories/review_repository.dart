import 'package:tutoring/features/reviews/domain/entities/review_item.dart';

abstract interface class ReviewRepository {
  /// Review items of one class, newest change first.
  Stream<List<ReviewItem>> watchReviews({
    required String userId,
    required String classId,
  });

  /// Every review item of the user across classes, newest change first.
  Stream<List<ReviewItem>> watchAllReviews({required String userId});

  Future<ReviewItem?> getReview({
    required String userId,
    required String reviewId,
  });

  /// Creates or updates the item for a wrong answer following
  /// [ReviewItem.recordWrongAnswer] and returns the stored item.
  Future<ReviewItem> recordWrongAnswer({
    required String userId,
    required String classId,
    required String quizId,
    required String questionId,
    required String? noteId,
    required String? blockId,
    required String topic,
    required String prompt,
    required int selectedOptionIndex,
  });

  Future<void> markReviewed({required String userId, required String reviewId});

  Future<void> deleteReview({required String userId, required String reviewId});

  /// Removes every review item of the user (account deletion).
  Future<void> deleteAllForUser(String userId);
}

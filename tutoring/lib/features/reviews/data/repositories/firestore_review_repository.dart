import 'package:tutoring/features/reviews/data/data_sources/review_remote_data_source.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';

class FirestoreReviewRepository implements ReviewRepository {
  const FirestoreReviewRepository(this._remoteDataSource);

  final ReviewRemoteDataSource _remoteDataSource;

  @override
  Stream<List<ReviewItem>> watchReviews({
    required String userId,
    required String classId,
  }) => _remoteDataSource
      .watchReviews(userId: userId, classId: classId)
      .map(
        (items) => items.map((item) => item.toDomain()).toList(growable: false),
      );

  @override
  Stream<List<ReviewItem>> watchAllReviews({required String userId}) =>
      _remoteDataSource
          .watchAllReviews(userId: userId)
          .map(
            (items) =>
                items.map((item) => item.toDomain()).toList(growable: false),
          );

  @override
  Future<ReviewItem?> getReview({
    required String userId,
    required String reviewId,
  }) async {
    final dto = await _remoteDataSource.getReview(
      userId: userId,
      reviewId: reviewId,
    );
    return dto?.toDomain();
  }

  @override
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
  }) async {
    final dto = await _remoteDataSource.recordWrongAnswer(
      userId: userId,
      classId: classId,
      quizId: quizId,
      questionId: questionId,
      noteId: noteId,
      blockId: blockId,
      topic: topic,
      prompt: prompt,
      selectedOptionIndex: selectedOptionIndex,
    );
    return dto.toDomain();
  }

  @override
  Future<void> markReviewed({
    required String userId,
    required String reviewId,
  }) => _remoteDataSource.markReviewed(userId: userId, reviewId: reviewId);

  @override
  Future<void> deleteReview({
    required String userId,
    required String reviewId,
  }) => _remoteDataSource.deleteReview(userId: userId, reviewId: reviewId);

  @override
  Future<void> deleteAllForUser(String userId) =>
      _remoteDataSource.deleteAllForUser(userId);
}

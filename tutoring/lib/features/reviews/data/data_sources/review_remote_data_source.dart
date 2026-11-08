import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/core/firebase/firestore_batch.dart';
import 'package:tutoring/features/reviews/data/dtos/review_dto.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

class ReviewRemoteDataSource {
  ReviewRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviews(String userId) =>
      _firestore
          .collection(FirebasePaths.users)
          .doc(userId)
          .collection(FirebasePaths.reviews);

  Stream<List<ReviewDto>> watchReviews({
    required String userId,
    required String classId,
  }) => _reviews(userId).where('classId', isEqualTo: classId).snapshots().map((
    snapshot,
  ) {
    final items = snapshot.docs
        .map(ReviewDto.fromFirestore)
        .toList(growable: true)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(items);
  });

  Stream<List<ReviewDto>> watchAllReviews({required String userId}) =>
      _reviews(userId).snapshots().map((snapshot) {
        final items = snapshot.docs
            .map(ReviewDto.fromFirestore)
            .toList(growable: true)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return List.unmodifiable(items);
      });

  Future<ReviewDto?> getReview({
    required String userId,
    required String reviewId,
  }) async {
    final snapshot = await _reviews(userId).doc(reviewId).get();
    if (!snapshot.exists) return null;
    return ReviewDto.fromFirestore(snapshot);
  }

  /// Reads the existing item and writes the merged one in a single
  /// transaction so repeated misses never lose a count.
  Future<ReviewDto> recordWrongAnswer({
    required String userId,
    required String classId,
    required String quizId,
    required String questionId,
    required String? noteId,
    required String? blockId,
    required String topic,
    required String prompt,
    required int selectedOptionIndex,
  }) {
    final reference = _reviews(userId).doc(
      ReviewItem.idFor(
        classId: classId,
        quizId: quizId,
        questionId: questionId,
      ),
    );
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing =
          snapshot.exists ? ReviewDto.fromFirestore(snapshot).toDomain() : null;
      final next = ReviewItem.recordWrongAnswer(
        existing: existing,
        userId: userId,
        classId: classId,
        quizId: quizId,
        questionId: questionId,
        noteId: noteId,
        blockId: blockId,
        topic: topic,
        prompt: prompt,
        selectedOptionIndex: selectedOptionIndex,
        now: DateTime.now(),
      );
      final dto = ReviewDto.fromDomain(next);
      transaction.set(reference, dto.toFirestore());
      return dto;
    });
  }

  Future<void> markReviewed({
    required String userId,
    required String reviewId,
  }) => _reviews(userId).doc(reviewId).update({
    'status': ReviewStatus.reviewed.firestoreValue,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });

  Future<void> deleteReview({
    required String userId,
    required String reviewId,
  }) => _reviews(userId).doc(reviewId).delete();

  Future<void> deleteAllForUser(String userId) =>
      deleteAllDocuments(_firestore, _reviews(userId));
}

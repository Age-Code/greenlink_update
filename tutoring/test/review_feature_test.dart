import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/reviews/data/dtos/review_dto.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

import 'helpers/fake_repositories.dart';

void main() {
  group('ReviewStatus', () {
    test('serializes one canonical value per status', () {
      expect(ReviewStatus.needsReview.firestoreValue, 'needsReview');
      expect(ReviewStatus.reviewed.firestoreValue, 'reviewed');
      expect(ReviewStatus.fromFirestore('reviewed'), ReviewStatus.reviewed);
      expect(
        ReviewStatus.fromFirestore('needsReview'),
        ReviewStatus.needsReview,
      );
      expect(ReviewStatus.fromFirestore(null), ReviewStatus.needsReview);
      expect(ReviewStatus.fromFirestore('junk'), ReviewStatus.needsReview);
    });
  });

  group('ReviewItem.recordWrongAnswer', () {
    final first = DateTime(2026, 11, 7, 9);
    final later = DateTime(2026, 11, 8, 10);

    ReviewItem record(ReviewItem? existing, DateTime now, {int option = 0}) =>
        ReviewItem.recordWrongAnswer(
          existing: existing,
          userId: 'tutee-1',
          classId: 'class-1',
          quizId: 'quiz-1',
          questionId: 'question-1',
          noteId: 'note-1',
          blockId: 'block-1',
          topic: 'Dictionary Quiz',
          prompt: '문제 1',
          selectedOptionIndex: option,
          now: now,
        );

    test('first miss creates the item with a deterministic id', () {
      final item = record(null, first);
      expect(item.id, 'class-1_quiz-1_question-1');
      expect(item.wrongCount, 1);
      expect(item.status, ReviewStatus.needsReview);
      expect(item.lastSelectedOptionIndex, 0);
      expect(item.createdAt, first);
      expect(item.updatedAt, first);
      expect(item.needsReview, isTrue);
    });

    test('repeated miss counts up, keeps createdAt and refreshes the choice',
        () {
      final item = record(record(null, first), later, option: 3);
      expect(item.wrongCount, 2);
      expect(item.lastSelectedOptionIndex, 3);
      expect(item.createdAt, first);
      expect(item.updatedAt, later);
    });

    test('a miss after review moves the item back to needsReview', () {
      final reviewed = record(null, first).copyWith(
        status: ReviewStatus.reviewed,
      );
      final item = record(reviewed, later);
      expect(item.status, ReviewStatus.needsReview);
      expect(item.wrongCount, 2);
    });
  });

  test('ReviewDto round-trips through Firestore values', () {
    final now = DateTime.utc(2026, 11, 8, 1);
    final dto = ReviewDto.fromMap('class-1_quiz-1_question-1', {
      'userId': 'tutee-1',
      'classId': 'class-1',
      'quizId': 'quiz-1',
      'questionId': 'question-1',
      'noteId': 'note-1',
      'blockId': null,
      'topic': 'Dictionary Quiz',
      'prompt': '문제 1',
      'lastSelectedOptionIndex': 2,
      'status': 'reviewed',
      'wrongCount': 3,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    final item = dto.toDomain();
    expect(item.status, ReviewStatus.reviewed);
    expect(item.wrongCount, 3);
    expect(item.blockId, isNull);
    expect(item.updatedAt.toUtc(), now);

    final stored = ReviewDto.fromDomain(item).toFirestore();
    expect(stored['status'], 'reviewed');
    expect(stored['wrongCount'], 3);
    expect(stored['lastSelectedOptionIndex'], 2);
    expect(stored['createdAt'], isA<Timestamp>());
    expect(stored.containsKey('id'), isFalse);
  });

  test('fake repository upserts one item per question and marks reviewed',
      () async {
    final repository = FakeReviewRepository();
    Future<ReviewItem> miss(String questionId, int option) =>
        repository.recordWrongAnswer(
          userId: 'tutee-1',
          classId: 'class-1',
          quizId: 'quiz-1',
          questionId: questionId,
          noteId: null,
          blockId: null,
          topic: 'Quiz',
          prompt: 'Q',
          selectedOptionIndex: option,
        );

    await miss('question-1', 0);
    await miss('question-1', 2);
    await miss('question-2', 1);
    expect(repository.items, hasLength(2));
    expect(repository.items['class-1_quiz-1_question-1']!.wrongCount, 2);

    await repository.markReviewed(
      userId: 'tutee-1',
      reviewId: 'class-1_quiz-1_question-1',
    );
    final reviews = await repository
        .watchReviews(userId: 'tutee-1', classId: 'class-1')
        .first;
    expect(
      reviews.where((item) => item.needsReview).map((item) => item.questionId),
      ['question-2'],
    );
    expect(
      await repository
          .watchReviews(userId: 'tutee-1', classId: 'other')
          .first,
      isEmpty,
    );
  });
}

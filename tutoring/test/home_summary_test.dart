import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/home/presentation/controllers/home_summary.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

import 'helpers/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 7, 18);

  test('quizzesSolvedOn counts only attempts finished on that day', () {
    final attempts = [
      sampleAttempt(id: 'today', quizId: 'quiz-1'), // testDate 09:03
      sampleAttempt(id: 'quick', quizId: 'quiz-1', noteId: 'note-2'),
    ];
    expect(quizzesSolvedOn(now, attempts), 2);
    expect(quizzesSolvedOn(now.add(const Duration(days: 1)), attempts), 0);
    expect(quizzesSolvedOn(now, const []), 0);
  });

  test('pendingReviewCount ignores items already checked again', () {
    final reviews = sampleReviews();
    expect(pendingReviewCount(reviews), 2);
    expect(
      reviews.where((item) => item.status == ReviewStatus.reviewed).length,
      1,
    );
  });

  test('classWithMostPendingReviews picks the busiest class', () {
    final reviews = [
      ...sampleReviews(),
      sampleReview(
        questionId: 'question-9',
        topic: 'Loop',
        prompt: 'while',
        classId: 'class-2',
      ),
    ];
    expect(classWithMostPendingReviews(reviews), 'class-1');
    expect(classWithMostPendingReviews(const []), isNull);
  });

  test('tutor counts: drafts and notes published in the last 7 days', () {
    final notes = [
      sampleNote(id: 'draft', week: 4, status: NoteStatus.draft),
      sampleNote(id: 'fresh', week: 3),
      sampleNote(
        id: 'old',
        week: 1,
      ).copyWith(publishedAt: now.subtract(const Duration(days: 20))),
    ];
    expect(draftNoteCount(notes), 1);
    expect(notesPublishedThisWeek(now, notes), 1);
  });
}

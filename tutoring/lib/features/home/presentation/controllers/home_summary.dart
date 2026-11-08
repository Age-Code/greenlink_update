import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

/// Pure helpers behind the home "오늘의 요약" card.

/// Clock behind "오늘" and "이번 주"; tests override it.
final homeClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Quiz attempts (inline Quick Checks included) finished on the day of [now].
int quizzesSolvedOn(DateTime now, Iterable<QuizAttempt> attempts) =>
    attempts
        .where((attempt) => isSameDay(attempt.completedAt.toLocal(), now))
        .length;

int pendingReviewCount(Iterable<ReviewItem> reviews) =>
    reviews.where((item) => item.status == ReviewStatus.needsReview).length;

/// Class holding the most pending reviews, where the 남은 복습 tile leads.
String? classWithMostPendingReviews(Iterable<ReviewItem> reviews) {
  final counts = <String, int>{};
  for (final item in reviews) {
    if (item.status != ReviewStatus.needsReview) continue;
    counts[item.classId] = (counts[item.classId] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

int draftNoteCount(Iterable<StudyNote> notes) =>
    notes.where((note) => note.status == NoteStatus.draft).length;

/// Notes published during the 7 days up to [now].
int notesPublishedThisWeek(DateTime now, Iterable<StudyNote> notes) {
  final since = now.subtract(const Duration(days: 7));
  return notes.where((note) {
    final publishedAt = note.publishedAt;
    return note.status == NoteStatus.published &&
        publishedAt != null &&
        !publishedAt.isBefore(since);
  }).length;
}

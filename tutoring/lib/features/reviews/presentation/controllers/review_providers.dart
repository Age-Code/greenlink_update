import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/data/note_data_providers.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/reviews/data/review_data_providers.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';

export 'package:tutoring/features/reviews/data/review_data_providers.dart'
    show reviewRepositoryProvider;

typedef ClassReviewKey = ({String userId, String classId});
typedef ReviewDetailKey = ({String userId, String classId, String reviewId});

/// Review items of the signed-in user for one class, newest first.
final classReviewsProvider =
    StreamProvider.family<List<ReviewItem>, ClassReviewKey>((ref, key) {
      return ref
          .watch(reviewRepositoryProvider)
          .watchReviews(userId: key.userId, classId: key.classId);
    });

/// Every review item of the signed-in user, all classes, newest first.
final myReviewsProvider = StreamProvider.family<List<ReviewItem>, String>((
  ref,
  userId,
) {
  return ref.watch(reviewRepositoryProvider).watchAllReviews(userId: userId);
});

/// One review item together with the live question and related note.
///
/// The tutor's question and note are read fresh; when either was deleted or
/// unpublished the field is null and the screen shows a notice instead.
class ReviewDetail {
  const ReviewDetail({
    required this.item,
    required this.question,
    required this.relatedNote,
  });

  final ReviewItem item;
  final QuizQuestion? question;
  final StudyNote? relatedNote;

  bool get hasQuestion => question != null;

  /// Option text the learner chose last time, if the question still exists.
  String? get selectedOptionLabel {
    final options = question?.options;
    final index = item.lastSelectedOptionIndex;
    if (options == null || index < 0 || index >= options.length) return null;
    return options[index];
  }

  String? get correctOptionLabel {
    final current = question;
    if (current == null) return null;
    if (current.correctOptionIndex < 0 ||
        current.correctOptionIndex >= current.options.length) {
      return null;
    }
    return current.options[current.correctOptionIndex];
  }
}

/// Loads a review item plus its question and note. Null when the item itself
/// is gone. Permission or network failures on the tutor content degrade to a
/// detail without question/note rather than an error.
final reviewDetailProvider = FutureProvider.autoDispose
    .family<ReviewDetail?, ReviewDetailKey>((ref, key) async {
      final item = await ref
          .watch(reviewRepositoryProvider)
          .getReview(userId: key.userId, reviewId: key.reviewId);
      if (item == null) return null;

      QuizQuestion? question;
      try {
        final quizRepository = ref.watch(quizRepositoryProvider);
        final quiz = await quizRepository.getQuiz(key.classId, item.quizId);
        if (quiz != null && quiz.status == QuizStatus.published) {
          final questions = await quizRepository.getQuestions(
            key.classId,
            item.quizId,
          );
          for (final candidate in questions) {
            if (candidate.id == item.questionId) {
              question = candidate;
              break;
            }
          }
        }
      } catch (_) {
        question = null;
      }

      StudyNote? relatedNote;
      final noteId = item.noteId;
      if (noteId != null && noteId.isNotEmpty) {
        try {
          relatedNote = await ref
              .watch(noteRepositoryProvider)
              .getNote(key.classId, noteId);
        } catch (_) {
          relatedNote = null;
        }
      }

      return ReviewDetail(
        item: item,
        question: question,
        relatedNote: relatedNote,
      );
    });

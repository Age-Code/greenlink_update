import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_writer.dart';

typedef QuizKey = ({String classId, String quizId});

final allQuizzesProvider = StreamProvider.family<List<StudyQuiz>, String>(
  (ref, classId) => ref.watch(quizRepositoryProvider).watchAllQuizzes(classId),
);

final publishedQuizzesProvider = StreamProvider.family<List<StudyQuiz>, String>(
  (ref, classId) =>
      ref.watch(quizRepositoryProvider).watchPublishedQuizzes(classId),
);

final quizAttemptsProvider = StreamProvider.family<List<QuizAttempt>, String>((
  ref,
  userId,
) {
  return ref.watch(quizAttemptRepositoryProvider).watchAttempts(userId);
});

final classQuizAttemptsProvider =
    StreamProvider.family<List<QuizAttempt>, String>((ref, classId) {
      return ref
          .watch(quizAttemptRepositoryProvider)
          .watchClassAttempts(classId);
    });

final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, QuizKey>(
      (ref, key) => ref
          .watch(quizRepositoryProvider)
          .getQuestions(key.classId, key.quizId),
    );

class QuizActionController extends StateNotifier<AsyncValue<void>> {
  QuizActionController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<String?> publish({
    required String classId,
    required String quizId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(quizRepositoryProvider);
      final quiz = await repository.getQuiz(classId, quizId);
      final questions = await repository.getQuestions(classId, quizId);
      if (quiz == null || quiz.title.trim().isEmpty) {
        state = const AsyncData(null);
        return '퀴즈 제목을 입력해주세요.';
      }
      if (questions.isEmpty) {
        state = const AsyncData(null);
        return '문제를 하나 이상 작성해주세요.';
      }
      final invalidIndex = questions.indexWhere(
        (question) => !question.isValid,
      );
      if (invalidIndex >= 0) {
        state = const AsyncData(null);
        return '문제 ${invalidIndex + 1}: ${questions[invalidIndex].validationError}';
      }
      await repository.setQuizStatus(
        classId: classId,
        quizId: quizId,
        status: QuizStatus.published,
      );
      await ref
          .read(notificationWriterProvider)
          .quizPublished(
            classId: classId,
            quizId: quizId,
            quizTitle: quiz.title,
          );
      state = const AsyncData(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return '퀴즈를 게시하지 못했어요.';
    }
  }

  Future<void> setStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(quizRepositoryProvider)
          .setQuizStatus(classId: classId, quizId: quizId, status: status),
    );
  }

  Future<void> deleteQuiz({
    required String classId,
    required String quizId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(quizRepositoryProvider).deleteQuiz(classId, quizId),
    );
  }
}

final quizActionControllerProvider =
    StateNotifierProvider<QuizActionController, AsyncValue<void>>((ref) {
      return QuizActionController(ref);
    });

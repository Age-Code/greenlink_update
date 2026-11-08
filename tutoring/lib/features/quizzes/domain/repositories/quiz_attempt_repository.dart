import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

abstract interface class QuizAttemptRepository {
  Stream<List<QuizAttempt>> watchAttempts(String userId);

  Stream<List<QuizAttempt>> watchClassAttempts(String classId);

  Future<String> createAttempt(QuizAttempt attempt);

  /// Removes every attempt of the user (account deletion).
  Future<void> deleteAllForUser(String userId);
}

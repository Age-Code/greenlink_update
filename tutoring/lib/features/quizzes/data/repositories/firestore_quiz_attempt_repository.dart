import 'package:tutoring/features/quizzes/data/data_sources/quiz_attempt_remote_data_source.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';

class FirestoreQuizAttemptRepository implements QuizAttemptRepository {
  const FirestoreQuizAttemptRepository(this._remoteDataSource);

  final QuizAttemptRemoteDataSource _remoteDataSource;

  @override
  Stream<List<QuizAttempt>> watchAttempts(String userId) => _remoteDataSource
      .watchAttempts(userId)
      .map(
        (items) => items.map((item) => item.toDomain()).toList(growable: false),
      );

  @override
  Stream<List<QuizAttempt>> watchClassAttempts(String classId) =>
      _remoteDataSource
          .watchClassAttempts(classId)
          .map(
            (items) =>
                items.map((item) => item.toDomain()).toList(growable: false),
          );

  @override
  Future<String> createAttempt(QuizAttempt attempt) =>
      _remoteDataSource.createAttempt(attempt);

  @override
  Future<void> deleteAllForUser(String userId) =>
      _remoteDataSource.deleteAllForUser(userId);
}

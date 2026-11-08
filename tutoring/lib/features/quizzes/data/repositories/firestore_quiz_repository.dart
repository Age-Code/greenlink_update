import 'package:tutoring/features/quizzes/data/data_sources/quiz_remote_data_source.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';

class FirestoreQuizRepository implements QuizRepository {
  const FirestoreQuizRepository(this._remoteDataSource);

  final QuizRemoteDataSource _remoteDataSource;

  @override
  Stream<List<StudyQuiz>> watchAllQuizzes(String classId) =>
      _remoteDataSource.watchAllQuizzes(classId).map(
            (items) => items
                .map((item) => item.toDomain())
                .toList(growable: false),
          );

  @override
  Stream<List<StudyQuiz>> watchPublishedQuizzes(String classId) =>
      _remoteDataSource.watchPublishedQuizzes(classId).map(
            (items) => items
                .map((item) => item.toDomain())
                .toList(growable: false),
          );

  @override
  Future<StudyQuiz?> getQuiz(String classId, String quizId) async =>
      (await _remoteDataSource.getQuiz(classId, quizId))?.toDomain();

  @override
  Future<List<QuizQuestion>> getQuestions(String classId, String quizId) async =>
      (await _remoteDataSource.getQuestions(classId, quizId))
          .map((item) => item.toDomain())
          .toList(growable: false);

  @override
  Future<String> saveQuiz({
    required StudyQuiz quiz,
    required List<QuizQuestion> questions,
  }) => _remoteDataSource.saveQuiz(quiz: quiz, questions: questions);

  @override
  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) => _remoteDataSource.setQuizStatus(
    classId: classId,
    quizId: quizId,
    status: status,
  );

  @override
  Future<void> deleteQuiz(String classId, String quizId) =>
      _remoteDataSource.deleteQuiz(classId, quizId);
}

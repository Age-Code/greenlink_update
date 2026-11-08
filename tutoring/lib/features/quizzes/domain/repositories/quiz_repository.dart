import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';

abstract interface class QuizRepository {
  Stream<List<StudyQuiz>> watchAllQuizzes(String classId);

  Stream<List<StudyQuiz>> watchPublishedQuizzes(String classId);

  Future<StudyQuiz?> getQuiz(String classId, String quizId);

  Future<List<QuizQuestion>> getQuestions(String classId, String quizId);

  Future<String> saveQuiz({
    required StudyQuiz quiz,
    required List<QuizQuestion> questions,
  });

  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  });

  Future<void> deleteQuiz(String classId, String quizId);
}

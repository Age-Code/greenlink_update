import 'package:tutoring/features/quizzes/domain/entities/quiz_answer.dart';

class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.classId,
    required this.quizId,
    required this.noteId,
    required this.startedAt,
    required this.completedAt,
    required this.totalQuestions,
    required this.correctCount,
    required this.answers,
  });

  final String id;
  final String userId;
  final String classId;
  final String quizId;
  final String? noteId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalQuestions;
  final int correctCount;
  final List<QuizAnswer> answers;
}

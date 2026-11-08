import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/quizzes/data/dtos/quiz_answer_dto.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

class QuizAttemptDto {
  const QuizAttemptDto({
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
  final List<QuizAnswerDto> answers;

  factory QuizAttemptDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawAnswers = data['answers'] as List<dynamic>? ?? const [];
    return QuizAttemptDto(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      quizId: data['quizId'] as String? ?? '',
      noteId: data['noteId'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      answers: rawAnswers
          .whereType<Map<String, dynamic>>()
          .map(QuizAnswerDto.fromMap)
          .toList(growable: false),
    );
  }

  factory QuizAttemptDto.fromDomain(QuizAttempt attempt) => QuizAttemptDto(
    id: attempt.id,
    userId: attempt.userId,
    classId: attempt.classId,
    quizId: attempt.quizId,
    noteId: attempt.noteId,
    startedAt: attempt.startedAt,
    completedAt: attempt.completedAt,
    totalQuestions: attempt.totalQuestions,
    correctCount: attempt.correctCount,
    answers: attempt.answers
        .map(QuizAnswerDto.fromDomain)
        .toList(growable: false),
  );

  Map<String, Object?> toFirestore() => {
    'id': id,
    'userId': userId,
    'classId': classId,
    'quizId': quizId,
    'noteId': noteId,
    'startedAt': Timestamp.fromDate(startedAt),
    'completedAt': Timestamp.fromDate(completedAt),
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'answers': answers.map((answer) => answer.toMap()).toList(growable: false),
  };

  QuizAttempt toDomain() => QuizAttempt(
    id: id,
    userId: userId,
    classId: classId,
    quizId: quizId,
    noteId: noteId,
    startedAt: startedAt,
    completedAt: completedAt,
    totalQuestions: totalQuestions,
    correctCount: correctCount,
    answers: answers.map((answer) => answer.toDomain()).toList(growable: false),
  );
}

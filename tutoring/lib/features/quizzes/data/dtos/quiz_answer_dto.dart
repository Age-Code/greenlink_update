import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_answer.dart';

class QuizAnswerDto {
  const QuizAnswerDto({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  final String questionId;
  final int selectedAnswer;
  final bool isCorrect;
  final DateTime answeredAt;

  factory QuizAnswerDto.fromMap(Map<String, dynamic> data) => QuizAnswerDto(
    questionId: data['questionId'] as String? ?? '',
    selectedAnswer: (data['selectedAnswer'] as num?)?.toInt() ?? -1,
    isCorrect: data['isCorrect'] as bool? ?? false,
    answeredAt: (data['answeredAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory QuizAnswerDto.fromDomain(QuizAnswer answer) => QuizAnswerDto(
    questionId: answer.questionId,
    selectedAnswer: answer.selectedAnswer,
    isCorrect: answer.isCorrect,
    answeredAt: answer.answeredAt,
  );

  Map<String, Object?> toMap() => {
    'questionId': questionId,
    'selectedAnswer': selectedAnswer,
    'isCorrect': isCorrect,
    'answeredAt': Timestamp.fromDate(answeredAt),
  };

  QuizAnswer toDomain() => QuizAnswer(
    questionId: questionId,
    selectedAnswer: selectedAnswer,
    isCorrect: isCorrect,
    answeredAt: answeredAt,
  );
}

class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  final String questionId;
  final int selectedAnswer;
  final bool isCorrect;
  final DateTime answeredAt;
}

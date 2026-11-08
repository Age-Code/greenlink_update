class QuickCheck {
  const QuickCheck({
    required this.quizId,
    required this.questionId,
    required this.classId,
    required this.noteId,
    required this.title,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String quizId;
  final String questionId;
  final String classId;
  final String noteId;
  final String title;
  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      options.length >= 2 &&
      options.every((option) => option.trim().isNotEmpty) &&
      correctOptionIndex >= 0 &&
      correctOptionIndex < options.length &&
      explanation.trim().isNotEmpty;

  QuickCheck copyWith({
    String? quizId,
    String? questionId,
    String? classId,
    String? noteId,
    String? title,
    String? prompt,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuickCheck(
    quizId: quizId ?? this.quizId,
    questionId: questionId ?? this.questionId,
    classId: classId ?? this.classId,
    noteId: noteId ?? this.noteId,
    title: title ?? this.title,
    prompt: prompt ?? this.prompt,
    options: options ?? this.options,
    correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    explanation: explanation ?? this.explanation,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

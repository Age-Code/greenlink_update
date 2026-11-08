enum QuizQuestionType {
  multipleChoice('multipleChoice');

  const QuizQuestionType(this.firestoreValue);

  final String firestoreValue;

  static QuizQuestionType fromFirestore(String? value) =>
      QuizQuestionType.multipleChoice;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.order,
    required this.relatedNoteId,
    required this.relatedBlockId,
  });

  final String id;
  final String quizId;
  final QuizQuestionType type;
  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int order;
  final String? relatedNoteId;
  final String? relatedBlockId;

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      options.length == 4 &&
      options.every((option) => option.trim().isNotEmpty) &&
      correctOptionIndex >= 0 &&
      correctOptionIndex < options.length &&
      explanation.trim().isNotEmpty;

  String? get validationError {
    if (prompt.trim().isEmpty) return '문제를 입력해주세요.';
    if (options.length != 4 ||
        options.any((option) => option.trim().isEmpty)) {
      return '선택지 4개를 모두 입력해주세요.';
    }
    if (correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      return '정답을 선택해주세요.';
    }
    if (explanation.trim().isEmpty) return '해설을 입력해주세요.';
    return null;
  }

  QuizQuestion copyWith({
    String? id,
    String? quizId,
    QuizQuestionType? type,
    String? prompt,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    int? order,
    String? relatedNoteId,
    String? relatedBlockId,
    bool clearRelatedNote = false,
    bool clearRelatedBlock = false,
  }) => QuizQuestion(
    id: id ?? this.id,
    quizId: quizId ?? this.quizId,
    type: type ?? this.type,
    prompt: prompt ?? this.prompt,
    options: options ?? this.options,
    correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    explanation: explanation ?? this.explanation,
    order: order ?? this.order,
    relatedNoteId: clearRelatedNote ? null : relatedNoteId ?? this.relatedNoteId,
    relatedBlockId:
        clearRelatedNote || clearRelatedBlock
            ? null
            : relatedBlockId ?? this.relatedBlockId,
  );
}

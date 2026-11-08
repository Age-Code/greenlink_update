import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';

class QuizQuestionDto {
  const QuizQuestionDto({
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

  factory QuizQuestionDto.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) => QuizQuestionDto(
    id: id,
    quizId: data['quizId'] as String? ?? '',
    type: QuizQuestionType.fromFirestore(data['type'] as String?),
    prompt: data['prompt'] as String? ?? '',
    options: (data['options'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    correctOptionIndex:
        (data['correctOptionIndex'] as num?)?.toInt() ??
        (data['correctAnswer'] as num?)?.toInt() ??
        -1,
    explanation: data['explanation'] as String? ?? '',
    order: (data['order'] as num?)?.toInt() ?? 0,
    relatedNoteId: data['relatedNoteId'] as String?,
    relatedBlockId: data['relatedBlockId'] as String?,
  );

  factory QuizQuestionDto.fromDomain(QuizQuestion question) => QuizQuestionDto(
    id: question.id,
    quizId: question.quizId,
    type: question.type,
    prompt: question.prompt,
    options: question.options,
    correctOptionIndex: question.correctOptionIndex,
    explanation: question.explanation,
    order: question.order,
    relatedNoteId: question.relatedNoteId,
    relatedBlockId: question.relatedBlockId,
  );

  Map<String, Object?> toFirestore() => {
    'quizId': quizId,
    'type': type.firestoreValue,
    'prompt': prompt,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'correctAnswer': correctOptionIndex,
    'explanation': explanation,
    'order': order,
    'relatedNoteId': relatedNoteId,
    'relatedBlockId': relatedBlockId,
  };

  QuizQuestion toDomain() => QuizQuestion(
    id: id,
    quizId: quizId,
    type: type,
    prompt: prompt,
    options: options,
    correctOptionIndex: correctOptionIndex,
    explanation: explanation,
    order: order,
    relatedNoteId: relatedNoteId,
    relatedBlockId: relatedBlockId,
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';

class QuickCheckDto {
  const QuickCheckDto({
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

  factory QuickCheckDto.fromFirestore({
    required String quizId,
    required String questionId,
    required Map<String, dynamic> quiz,
    required Map<String, dynamic> question,
  }) {
    final createdAt = (quiz['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (quiz['updatedAt'] as Timestamp?)?.toDate();
    return QuickCheckDto(
      quizId: quizId,
      questionId: questionId,
      classId: quiz['classId'] as String? ?? '',
      noteId: quiz['noteId'] as String? ?? '',
      title: quiz['title'] as String? ?? 'Quick Check',
      prompt: question['prompt'] as String? ?? '',
      options: (question['options'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      correctOptionIndex: (question['correctOptionIndex'] as num?)?.toInt() ?? -1,
      explanation: question['explanation'] as String? ?? '',
      createdBy: quiz['createdBy'] as String? ?? '',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory QuickCheckDto.fromDomain(QuickCheck quickCheck) => QuickCheckDto(
    quizId: quickCheck.quizId,
    questionId: quickCheck.questionId,
    classId: quickCheck.classId,
    noteId: quickCheck.noteId,
    title: quickCheck.title,
    prompt: quickCheck.prompt,
    options: quickCheck.options,
    correctOptionIndex: quickCheck.correctOptionIndex,
    explanation: quickCheck.explanation,
    createdBy: quickCheck.createdBy,
    createdAt: quickCheck.createdAt,
    updatedAt: quickCheck.updatedAt,
  );

  Map<String, Object?> quizToFirestore() => {
    'classId': classId,
    'noteId': noteId,
    'title': title,
    'description': '',
    'status': 'published',
    'questionCount': 1,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, Object?> questionToFirestore({String? relatedBlockId}) => {
    'quizId': quizId,
    'type': 'multipleChoice',
    'prompt': prompt,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'explanation': explanation,
    'order': 0,
    'relatedNoteId': noteId,
    'relatedBlockId': relatedBlockId,
  };

  QuickCheck toDomain() => QuickCheck(
    quizId: quizId,
    questionId: questionId,
    classId: classId,
    noteId: noteId,
    title: title,
    prompt: prompt,
    options: options,
    correctOptionIndex: correctOptionIndex,
    explanation: explanation,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

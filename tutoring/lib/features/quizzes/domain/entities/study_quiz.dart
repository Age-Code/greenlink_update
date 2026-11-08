import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';

class StudyQuiz {
  const StudyQuiz({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.questionCount,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
    required this.noteId,
  });

  final String id;
  final String classId;
  final String title;
  final String description;
  final String createdBy;
  final QuizStatus status;
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? noteId;

  StudyQuiz copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? createdBy,
    QuizStatus? status,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? noteId,
    bool clearPublishedAt = false,
  }) => StudyQuiz(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    title: title ?? this.title,
    description: description ?? this.description,
    createdBy: createdBy ?? this.createdBy,
    status: status ?? this.status,
    questionCount: questionCount ?? this.questionCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
    noteId: noteId ?? this.noteId,
  );
}

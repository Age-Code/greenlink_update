import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';

class QuizDto {
  const QuizDto({
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

  factory QuizDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return QuizDto(
      id: document.id,
      classId: data['classId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      status: QuizStatus.fromFirestore(data['status'] as String?),
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      noteId: data['noteId'] as String?,
    );
  }

  factory QuizDto.fromDomain(StudyQuiz quiz) => QuizDto(
    id: quiz.id,
    classId: quiz.classId,
    title: quiz.title,
    description: quiz.description,
    createdBy: quiz.createdBy,
    status: quiz.status,
    questionCount: quiz.questionCount,
    createdAt: quiz.createdAt,
    updatedAt: quiz.updatedAt,
    publishedAt: quiz.publishedAt,
    noteId: quiz.noteId,
  );

  Map<String, Object?> toFirestore() => {
    'classId': classId,
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'status': status.firestoreValue,
    'questionCount': questionCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null ? null : Timestamp.fromDate(publishedAt!),
    'noteId': noteId,
  };

  StudyQuiz toDomain() => StudyQuiz(
    id: id,
    classId: classId,
    title: title,
    description: description,
    createdBy: createdBy,
    status: status,
    questionCount: questionCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    publishedAt: publishedAt,
    noteId: noteId,
  );
}

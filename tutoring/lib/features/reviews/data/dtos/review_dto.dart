import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.userId,
    required this.classId,
    required this.quizId,
    required this.questionId,
    required this.noteId,
    required this.blockId,
    required this.topic,
    required this.prompt,
    required this.lastSelectedOptionIndex,
    required this.status,
    required this.wrongCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String classId;
  final String quizId;
  final String questionId;
  final String? noteId;
  final String? blockId;
  final String topic;
  final String prompt;
  final int lastSelectedOptionIndex;
  final ReviewStatus status;
  final int wrongCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReviewDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => ReviewDto.fromMap(document.id, document.data() ?? const {});

  factory ReviewDto.fromMap(String id, Map<String, dynamic> data) => ReviewDto(
    id: id,
    userId: data['userId'] as String? ?? '',
    classId: data['classId'] as String? ?? '',
    quizId: data['quizId'] as String? ?? '',
    questionId: data['questionId'] as String? ?? '',
    noteId: data['noteId'] as String?,
    blockId: data['blockId'] as String?,
    topic: data['topic'] as String? ?? '',
    prompt: data['prompt'] as String? ?? '',
    lastSelectedOptionIndex:
        (data['lastSelectedOptionIndex'] as num?)?.toInt() ?? -1,
    status: ReviewStatus.fromFirestore(data['status'] as String?),
    wrongCount: (data['wrongCount'] as num?)?.toInt() ?? 0,
    createdAt:
        (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        (data['updatedAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory ReviewDto.fromDomain(ReviewItem item) => ReviewDto(
    id: item.id,
    userId: item.userId,
    classId: item.classId,
    quizId: item.quizId,
    questionId: item.questionId,
    noteId: item.noteId,
    blockId: item.blockId,
    topic: item.topic,
    prompt: item.prompt,
    lastSelectedOptionIndex: item.lastSelectedOptionIndex,
    status: item.status,
    wrongCount: item.wrongCount,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  );

  Map<String, Object?> toFirestore() => {
    'userId': userId,
    'classId': classId,
    'quizId': quizId,
    'questionId': questionId,
    'noteId': noteId,
    'blockId': blockId,
    'topic': topic,
    'prompt': prompt,
    'lastSelectedOptionIndex': lastSelectedOptionIndex,
    'status': status.firestoreValue,
    'wrongCount': wrongCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  ReviewItem toDomain() => ReviewItem(
    id: id,
    userId: userId,
    classId: classId,
    quizId: quizId,
    questionId: questionId,
    noteId: noteId,
    blockId: blockId,
    topic: topic,
    prompt: prompt,
    lastSelectedOptionIndex: lastSelectedOptionIndex,
    status: status,
    wrongCount: wrongCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

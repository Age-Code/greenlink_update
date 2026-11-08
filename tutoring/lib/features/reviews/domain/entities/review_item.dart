import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

/// One quiz question a learner answered wrong, stored under
/// `users/{uid}/reviews/{classId_quizId_questionId}`.
///
/// Only display snapshots ([topic], [prompt]) are copied from tutor content;
/// the live question is always read through [classId], [quizId] and
/// [questionId], so tutor edits are never overwritten.
class ReviewItem {
  const ReviewItem({
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

  /// Quiz title at the time of the last wrong answer.
  final String topic;

  /// Question text at the time of the last wrong answer.
  final String prompt;

  final int lastSelectedOptionIndex;
  final ReviewStatus status;
  final int wrongCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get needsReview => status == ReviewStatus.needsReview;

  /// Deterministic document id, so the same question always maps to one item.
  static String idFor({
    required String classId,
    required String quizId,
    required String questionId,
  }) => '${classId}_${quizId}_$questionId';

  /// Upsert rule for a wrong answer. A first miss creates the item with
  /// `wrongCount` 1; every later miss adds one, refreshes the snapshot and the
  /// chosen option, and moves the item back to [ReviewStatus.needsReview].
  static ReviewItem recordWrongAnswer({
    required ReviewItem? existing,
    required String userId,
    required String classId,
    required String quizId,
    required String questionId,
    required String? noteId,
    required String? blockId,
    required String topic,
    required String prompt,
    required int selectedOptionIndex,
    required DateTime now,
  }) => ReviewItem(
    id: idFor(classId: classId, quizId: quizId, questionId: questionId),
    userId: userId,
    classId: classId,
    quizId: quizId,
    questionId: questionId,
    noteId: noteId,
    blockId: blockId,
    topic: topic,
    prompt: prompt,
    lastSelectedOptionIndex: selectedOptionIndex,
    status: ReviewStatus.needsReview,
    wrongCount: (existing?.wrongCount ?? 0) + 1,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  );

  ReviewItem copyWith({ReviewStatus? status, DateTime? updatedAt}) =>
      ReviewItem(
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
        status: status ?? this.status,
        wrongCount: wrongCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

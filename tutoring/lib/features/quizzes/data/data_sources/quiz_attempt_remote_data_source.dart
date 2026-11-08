import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/core/firebase/firestore_batch.dart';
import 'package:tutoring/features/quizzes/data/dtos/quiz_attempt_dto.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

class QuizAttemptRemoteDataSource {
  QuizAttemptRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _attempts(String userId) =>
      _firestore
          .collection(FirebasePaths.users)
          .doc(userId)
          .collection(FirebasePaths.quizAttempts);

  Stream<List<QuizAttemptDto>> watchAttempts(String userId) => _attempts(userId)
      .orderBy('completedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(QuizAttemptDto.fromFirestore)
            .toList(growable: false),
      );

  Stream<List<QuizAttemptDto>> watchClassAttempts(String classId) => _firestore
      .collectionGroup(FirebasePaths.quizAttempts)
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs
            .map(QuizAttemptDto.fromFirestore)
            .toList(growable: true)
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return List.unmodifiable(items);
      });

  Future<void> deleteAllForUser(String userId) =>
      deleteAllDocuments(_firestore, _attempts(userId));

  Future<String> createAttempt(QuizAttempt attempt) async {
    final reference = _attempts(attempt.userId).doc();
    final stored = QuizAttempt(
      id: reference.id,
      userId: attempt.userId,
      classId: attempt.classId,
      quizId: attempt.quizId,
      noteId: attempt.noteId,
      startedAt: attempt.startedAt,
      completedAt: attempt.completedAt,
      totalQuestions: attempt.totalQuestions,
      correctCount: attempt.correctCount,
      answers: attempt.answers,
    );
    await reference.set(QuizAttemptDto.fromDomain(stored).toFirestore());
    return reference.id;
  }
}

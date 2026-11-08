import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/features/quizzes/data/dtos/quiz_dto.dart';
import 'package:tutoring/features/quizzes/data/dtos/quiz_question_dto.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';

class QuizRemoteDataSource {
  QuizRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _quizzes(String classId) =>
      _firestore
          .collection(FirebasePaths.classes)
          .doc(classId)
          .collection(FirebasePaths.quizzes);

  Stream<List<QuizDto>> watchAllQuizzes(String classId) {
    return _quizzes(classId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(QuizDto.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<QuizDto>> watchPublishedQuizzes(String classId) {
    return _quizzes(classId)
        .where('status', isEqualTo: QuizStatus.published.firestoreValue)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(QuizDto.fromFirestore).toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<QuizDto?> getQuiz(String classId, String quizId) async {
    final snapshot = await _quizzes(classId).doc(quizId).get();
    return snapshot.exists ? QuizDto.fromFirestore(snapshot) : null;
  }

  Future<List<QuizQuestionDto>> getQuestions(
    String classId,
    String quizId,
  ) async {
    final snapshot = await _quizzes(classId)
        .doc(quizId)
        .collection(FirebasePaths.questions)
        .orderBy('order')
        .get();
    return snapshot.docs
        .map(
          (document) => QuizQuestionDto.fromFirestore(
            id: document.id,
            data: document.data(),
          ),
        )
        .toList(growable: false);
  }

  Future<String> saveQuiz({
    required StudyQuiz quiz,
    required List<QuizQuestion> questions,
  }) async {
    final quizReference =
        quiz.id.isEmpty ? _quizzes(quiz.classId).doc() : _quizzes(quiz.classId).doc(quiz.id);
    final quizId = quizReference.id;
    final questionsReference = quizReference.collection(FirebasePaths.questions);
    final previousQuestions = quiz.id.isEmpty
        ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : (await questionsReference.get()).docs;
    final batch = _firestore.batch();
    final storedQuiz = quiz.copyWith(
      id: quizId,
      questionCount: questions.length,
    );
    batch.set(quizReference, QuizDto.fromDomain(storedQuiz).toFirestore());

    final incomingIds = <String>{};
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final questionId =
          question.id.isEmpty ? questionsReference.doc().id : question.id;
      incomingIds.add(questionId);
      final storedQuestion = question.copyWith(
        id: questionId,
        quizId: quizId,
        order: index,
      );
      batch.set(
        questionsReference.doc(questionId),
        QuizQuestionDto.fromDomain(storedQuestion).toFirestore(),
      );
    }

    for (final previous in previousQuestions) {
      if (!incomingIds.contains(previous.id)) batch.delete(previous.reference);
    }
    await batch.commit();
    return quizId;
  }

  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) {
    return _quizzes(classId).doc(quizId).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
      'publishedAt': status == QuizStatus.published
          ? FieldValue.serverTimestamp()
          : null,
    });
  }

  Future<void> deleteQuiz(String classId, String quizId) async {
    final quizReference = _quizzes(classId).doc(quizId);
    final questions = await quizReference
        .collection(FirebasePaths.questions)
        .get();
    final batch = _firestore.batch();
    for (final question in questions.docs) {
      batch.delete(question.reference);
    }
    batch.delete(quizReference);
    await batch.commit();
  }
}

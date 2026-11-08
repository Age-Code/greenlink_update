import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/features/notes/data/dtos/note_block_dto.dart';
import 'package:tutoring/features/notes/data/dtos/note_dto.dart';
import 'package:tutoring/features/notes/data/dtos/quick_check_dto.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

class NoteRemoteDataSource {
  NoteRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notes(String classId) =>
      _firestore
          .collection(FirebasePaths.classes)
          .doc(classId)
          .collection(FirebasePaths.notes);

  CollectionReference<Map<String, dynamic>> _quizzes(String classId) =>
      _firestore
          .collection(FirebasePaths.classes)
          .doc(classId)
          .collection(FirebasePaths.quizzes);

  Stream<List<NoteDto>> watchPublishedNotes(String classId) {
    return _notes(classId)
        .where('status', isEqualTo: 'published')
        .orderBy('week', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NoteDto.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NoteDto>> watchAllNotes(String classId) {
    return _notes(classId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NoteDto.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<NoteDto?> getNote(String classId, String noteId) async {
    final snapshot = await _notes(classId).doc(noteId).get();
    return snapshot.exists ? NoteDto.fromFirestore(snapshot) : null;
  }

  Future<List<NoteBlockDto>> getNoteBlocks(
    String classId,
    String noteId,
  ) async {
    final snapshot = await _notes(classId)
        .doc(noteId)
        .collection(FirebasePaths.blocks)
        .orderBy('order')
        .get();
    return snapshot.docs.map(NoteBlockDto.fromFirestore).toList(growable: false);
  }

  Stream<List<NoteBlockDto>> watchNoteBlocks(
    String classId,
    String noteId,
  ) {
    return _notes(classId)
        .doc(noteId)
        .collection(FirebasePaths.blocks)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NoteBlockDto.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<QuickCheckDto?> getQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) async {
    final quizReference = _quizzes(classId).doc(quizId);
    final results = await Future.wait([
      quizReference.get(),
      quizReference.collection(FirebasePaths.questions).doc(questionId).get(),
    ]);
    final quiz = results[0];
    final question = results[1];
    if (!quiz.exists || !question.exists) return null;
    return QuickCheckDto.fromFirestore(
      quizId: quizId,
      questionId: questionId,
      quiz: quiz.data() ?? const <String, dynamic>{},
      question: question.data() ?? const <String, dynamic>{},
    );
  }

  Stream<QuickCheckDto?> watchQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) {
    final quizReference = _quizzes(classId).doc(quizId);
    final questionReference = quizReference
        .collection(FirebasePaths.questions)
        .doc(questionId);
    return quizReference.snapshots().asyncExpand((quiz) {
      if (!quiz.exists) return Stream<QuickCheckDto?>.value(null);
      return questionReference.snapshots().map((question) {
        if (!question.exists) return null;
        return QuickCheckDto.fromFirestore(
          quizId: quizId,
          questionId: questionId,
          quiz: quiz.data() ?? const <String, dynamic>{},
          question: question.data() ?? const <String, dynamic>{},
        );
      });
    });
  }

  Future<String> saveNote({
    required StudyNote note,
    required List<NoteBlock> blocks,
    required Map<String, QuickCheck> quickChecksByBlockId,
  }) async {
    final noteReference = note.id.isEmpty ? _notes(note.classId).doc() : _notes(note.classId).doc(note.id);
    final noteId = noteReference.id;
    final blocksReference = noteReference.collection(FirebasePaths.blocks);
    final previousBlocks = note.id.isEmpty ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[] : (await blocksReference.get()).docs;
    final sharedQuizIds = <String>{};
    for (final quickCheck in quickChecksByBlockId.values) {
      if (sharedQuizIds.contains(quickCheck.quizId)) continue;
      final snapshot = await _quizzes(note.classId).doc(quickCheck.quizId).get();
      if (snapshot.exists && snapshot.data()?['noteId'] != noteId) {
        sharedQuizIds.add(quickCheck.quizId);
      }
    }
    final batch = _firestore.batch();
    final storedNote = note.copyWith(id: noteId);
    batch.set(noteReference, NoteDto.fromDomain(storedNote).toFirestore());

    final incomingIds = <String>{};
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      final blockId = block.id.isEmpty ? blocksReference.doc().id : block.id;
      incomingIds.add(blockId);
      final storedBlock = block.copyWith(
        id: blockId,
        noteId: noteId,
        order: index,
      );
      batch.set(
        blocksReference.doc(blockId),
        NoteBlockDto.fromDomain(storedBlock).toFirestore(),
      );

      final quickCheck = quickChecksByBlockId[block.id];
      if (storedBlock.type == NoteBlockType.quiz &&
          quickCheck != null &&
          !sharedQuizIds.contains(quickCheck.quizId)) {
        final storedQuickCheck = quickCheck.copyWith(
          classId: note.classId,
          noteId: noteId,
          updatedAt: note.updatedAt,
        );
        final quizReference = _quizzes(note.classId).doc(storedQuickCheck.quizId);
        final questionReference = quizReference
            .collection(FirebasePaths.questions)
            .doc(storedQuickCheck.questionId);
        final dto = QuickCheckDto.fromDomain(storedQuickCheck);
        batch.set(quizReference, dto.quizToFirestore());
        batch.set(
          questionReference,
          dto.questionToFirestore(relatedBlockId: storedBlock.id),
        );
      }
    }

    for (final previous in previousBlocks) {
      if (incomingIds.contains(previous.id)) continue;
      batch.delete(previous.reference);
    }
    await batch.commit();
    return noteId;
  }

  Future<void> setNoteStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  }) {
    return _notes(classId).doc(noteId).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
      'publishedAt': status == NoteStatus.published
          ? FieldValue.serverTimestamp()
          : null,
    });
  }

  Future<void> deleteNote(String classId, String noteId) async {
    final noteReference = _notes(classId).doc(noteId);
    final blocks = await noteReference.collection(FirebasePaths.blocks).get();
    final batch = _firestore.batch();
    for (final block in blocks.docs) {
      batch.delete(block.reference);
    }
    batch.delete(noteReference);
    await batch.commit();
  }
}

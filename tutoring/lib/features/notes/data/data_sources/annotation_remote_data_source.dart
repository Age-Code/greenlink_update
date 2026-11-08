import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/core/firebase/firestore_batch.dart';
import 'package:tutoring/features/notes/data/dtos/annotation_dto.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';

class AnnotationRemoteDataSource {
  AnnotationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _annotations(String userId) =>
      _firestore
          .collection(FirebasePaths.users)
          .doc(userId)
          .collection(FirebasePaths.annotations);

  Future<void> deleteAllForUser(String userId) =>
      deleteAllDocuments(_firestore, _annotations(userId));

  Stream<List<AnnotationDto>> watchAnnotations({
    required String userId,
    required String noteId,
  }) {
    return _annotations(
      userId,
    ).where('noteId', isEqualTo: noteId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(AnnotationDto.fromFirestore)
          .toList(growable: true);
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return List.unmodifiable(items);
    });
  }

  Future<AnnotationDto> createAnnotation({
    required String userId,
    required String classId,
    required String noteId,
    required String? blockId,
    required AnnotationType type,
    required String content,
    String? selectedText,
    int? startOffset,
    int? endOffset,
  }) async {
    final reference = _annotations(userId).doc();
    final now = DateTime.now();
    final dto = AnnotationDto(
      id: reference.id,
      userId: userId,
      classId: classId,
      noteId: noteId,
      blockId: blockId,
      type: type.firestoreValue,
      content: content,
      selectedText: selectedText,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: now,
      updatedAt: now,
    );
    await reference.set(dto.toFirestore());
    return dto;
  }

  Future<void> updateAnnotation(StudyAnnotation annotation) {
    final dto = AnnotationDto.fromDomain(annotation);
    return _annotations(annotation.userId).doc(annotation.id).update({
      ...dto.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAnnotation(StudyAnnotation annotation) {
    final dto = AnnotationDto.fromDomain(annotation);
    return _annotations(
      annotation.userId,
    ).doc(annotation.id).set(dto.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteAnnotation({
    required String userId,
    required String annotationId,
  }) => _annotations(userId).doc(annotationId).delete();
}

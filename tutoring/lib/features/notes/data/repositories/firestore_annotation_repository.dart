import 'package:tutoring/features/notes/data/data_sources/annotation_remote_data_source.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/repositories/annotation_repository.dart';

class FirestoreAnnotationRepository implements AnnotationRepository {
  const FirestoreAnnotationRepository(this._remoteDataSource);

  final AnnotationRemoteDataSource _remoteDataSource;

  @override
  Stream<List<StudyAnnotation>> watchAnnotations({
    required String userId,
    required String noteId,
  }) => _remoteDataSource
      .watchAnnotations(userId: userId, noteId: noteId)
      .map(
        (items) => items.map((item) => item.toDomain()).toList(growable: false),
      );

  @override
  Future<StudyAnnotation> createAnnotation({
    required String userId,
    required String classId,
    required String noteId,
    required String? blockId,
    required AnnotationType type,
    required String content,
    String? selectedText,
    int? startOffset,
    int? endOffset,
  }) async =>
      (await _remoteDataSource.createAnnotation(
        userId: userId,
        classId: classId,
        noteId: noteId,
        blockId: blockId,
        type: type,
        content: content,
        selectedText: selectedText,
        startOffset: startOffset,
        endOffset: endOffset,
      )).toDomain();

  @override
  Future<void> updateAnnotation(StudyAnnotation annotation) =>
      _remoteDataSource.updateAnnotation(annotation);

  @override
  Future<void> saveAnnotation(StudyAnnotation annotation) =>
      _remoteDataSource.saveAnnotation(annotation);

  @override
  Future<void> deleteAnnotation({
    required String userId,
    required String annotationId,
  }) => _remoteDataSource.deleteAnnotation(
    userId: userId,
    annotationId: annotationId,
  );

  @override
  Future<void> deleteAllForUser(String userId) =>
      _remoteDataSource.deleteAllForUser(userId);
}

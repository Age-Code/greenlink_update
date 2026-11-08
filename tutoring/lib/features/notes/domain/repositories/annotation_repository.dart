import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';

abstract interface class AnnotationRepository {
  Stream<List<StudyAnnotation>> watchAnnotations({
    required String userId,
    required String noteId,
  });

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
  });

  Future<void> updateAnnotation(StudyAnnotation annotation);

  Future<void> saveAnnotation(StudyAnnotation annotation);

  Future<void> deleteAnnotation({
    required String userId,
    required String annotationId,
  });

  /// Removes every annotation of the user (account deletion).
  Future<void> deleteAllForUser(String userId);
}

enum AnnotationType {
  highlight('highlight'),
  memo('memo'),
  bookmark('bookmark'),
  drawing('drawing'),
  freehandHighlight('freehandHighlight'),
  text('text');

  const AnnotationType(this.firestoreValue);

  final String firestoreValue;

  static AnnotationType fromFirestore(String? value) => switch (value) {
    'memo' => AnnotationType.memo,
    'bookmark' => AnnotationType.bookmark,
    'drawing' => AnnotationType.drawing,
    'freehandHighlight' => AnnotationType.freehandHighlight,
    'text' => AnnotationType.text,
    _ => AnnotationType.highlight,
  };
}

class AnnotationPoint {
  const AnnotationPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class AnnotationStroke {
  const AnnotationStroke({
    required this.points,
    required this.width,
    required this.colorValue,
  });

  final List<AnnotationPoint> points;
  final double width;
  final int colorValue;
}

class StudyAnnotation {
  const StudyAnnotation({
    required this.id,
    required this.userId,
    required this.classId,
    required this.noteId,
    required this.blockId,
    required this.type,
    required this.content,
    required this.selectedText,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    required this.updatedAt,
    this.strokes = const <AnnotationStroke>[],
    this.positionX,
    this.positionY,
  });

  final String id;
  final String userId;
  final String classId;
  final String noteId;
  final String? blockId;
  final AnnotationType type;
  final String content;
  final String? selectedText;
  final int? startOffset;
  final int? endOffset;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AnnotationStroke> strokes;
  final double? positionX;
  final double? positionY;

  StudyAnnotation copyWith({
    String? content,
    List<AnnotationStroke>? strokes,
    double? positionX,
    double? positionY,
    DateTime? updatedAt,
  }) => StudyAnnotation(
        id: id,
        userId: userId,
        classId: classId,
        noteId: noteId,
        blockId: blockId,
        type: type,
        content: content ?? this.content,
        selectedText: selectedText,
        startOffset: startOffset,
        endOffset: endOffset,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        strokes: strokes ?? this.strokes,
        positionX: positionX ?? this.positionX,
        positionY: positionY ?? this.positionY,
      );
}

StudyAnnotation? findBookmark(Iterable<StudyAnnotation> annotations) {
  for (final annotation in annotations) {
    if (annotation.type == AnnotationType.bookmark) return annotation;
  }
  return null;
}

StudyAnnotation? findBlockHighlight(
  Iterable<StudyAnnotation> annotations,
  String blockId,
) {
  for (final annotation in annotations) {
    if (annotation.type == AnnotationType.highlight &&
        annotation.blockId == blockId) {
      return annotation;
    }
  }
  return null;
}

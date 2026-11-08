import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';

class AnnotationDto {
  const AnnotationDto({
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
  final String type;
  final String content;
  final String? selectedText;
  final int? startOffset;
  final int? endOffset;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AnnotationStroke> strokes;
  final double? positionX;
  final double? positionY;

  factory AnnotationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => AnnotationDto.fromMap(
    snapshot.id,
    snapshot.data() ?? const <String, dynamic>{},
  );

  factory AnnotationDto.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    return AnnotationDto(
      id: id,
      userId: data['userId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      noteId: data['noteId'] as String? ?? '',
      blockId: data['blockId'] as String?,
      type: data['type'] as String? ?? 'highlight',
      content: data['content'] as String? ?? '',
      selectedText: data['selectedText'] as String?,
      startOffset: (data['startOffset'] as num?)?.toInt(),
      endOffset: (data['endOffset'] as num?)?.toInt(),
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      strokes: _strokesFromMap(data['strokes']),
      positionX: (data['positionX'] as num?)?.toDouble(),
      positionY: (data['positionY'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toFirestore() => {
    'userId': userId,
    'classId': classId,
    'noteId': noteId,
    'blockId': blockId,
    'type': type,
    'content': content,
    'selectedText': selectedText,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'strokes': strokes
        .map(
          (stroke) => <String, Object?>{
            'width': stroke.width,
            'colorValue': stroke.colorValue,
            'points': stroke.points
                .map((point) => <String, double>{'x': point.x, 'y': point.y})
                .toList(growable: false),
          },
        )
        .toList(growable: false),
    'positionX': positionX,
    'positionY': positionY,
  };

  factory AnnotationDto.fromDomain(StudyAnnotation annotation) => AnnotationDto(
    id: annotation.id,
    userId: annotation.userId,
    classId: annotation.classId,
    noteId: annotation.noteId,
    blockId: annotation.blockId,
    type: annotation.type.firestoreValue,
    content: annotation.content,
    selectedText: annotation.selectedText,
    startOffset: annotation.startOffset,
    endOffset: annotation.endOffset,
    createdAt: annotation.createdAt,
    updatedAt: annotation.updatedAt,
    strokes: annotation.strokes,
    positionX: annotation.positionX,
    positionY: annotation.positionY,
  );

  StudyAnnotation toDomain() => StudyAnnotation(
    id: id,
    userId: userId,
    classId: classId,
    noteId: noteId,
    blockId: blockId,
    type: AnnotationType.fromFirestore(type),
    content: content,
    selectedText: selectedText,
    startOffset: startOffset,
    endOffset: endOffset,
    createdAt: createdAt,
    updatedAt: updatedAt,
    strokes: strokes,
    positionX: positionX,
    positionY: positionY,
  );
}

List<AnnotationStroke> _strokesFromMap(Object? value) {
  if (value is! List) return const <AnnotationStroke>[];
  return value.whereType<Map>().map((rawStroke) {
    final rawPoints = rawStroke['points'];
    final points = rawPoints is List
        ? rawPoints.whereType<Map>().map((rawPoint) {
            return AnnotationPoint(
              x: ((rawPoint['x'] as num?)?.toDouble() ?? 0)
                  .clamp(0, 1)
                  .toDouble(),
              y: ((rawPoint['y'] as num?)?.toDouble() ?? 0)
                  .clamp(0, 1)
                  .toDouble(),
            );
          }).toList(growable: false)
        : const <AnnotationPoint>[];
    return AnnotationStroke(
      points: points,
      width: (rawStroke['width'] as num?)?.toDouble() ?? 2.5,
      colorValue: (rawStroke['colorValue'] as num?)?.toInt() ?? 0xFF5D4E49,
    );
  }).toList(growable: false);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

class NoteDto {
  const NoteDto({
    required this.id,
    required this.classId,
    required this.title,
    required this.summary,
    required this.week,
    required this.authorId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
  });

  final String id;
  final String classId;
  final String title;
  final String summary;
  final int week;
  final String authorId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  factory NoteDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => NoteDto.fromMap(
    snapshot.id,
    snapshot.data() ?? const <String, dynamic>{},
  );

  factory NoteDto.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    return NoteDto(
      id: id,
      classId: data['classId'] as String? ?? '',
      title: data['title'] as String? ?? '이름 없는 노트',
      summary: data['summary'] as String? ?? '',
      week: (data['week'] as num?)?.toInt() ?? 0,
      authorId: data['authorId'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  StudyNote toDomain() => StudyNote(
    id: id,
    classId: classId,
    title: title,
    summary: summary,
    week: week,
    authorId: authorId,
    status: NoteStatus.fromFirestore(status),
    createdAt: createdAt,
    updatedAt: updatedAt,
    publishedAt: publishedAt,
  );

  factory NoteDto.fromDomain(StudyNote note) => NoteDto(
    id: note.id,
    classId: note.classId,
    title: note.title,
    summary: note.summary,
    week: note.week,
    authorId: note.authorId,
    status: note.status.firestoreValue,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    publishedAt: note.publishedAt,
  );

  Map<String, Object?> toFirestore() => {
    'classId': classId,
    'title': title,
    'summary': summary,
    'week': week,
    'authorId': authorId,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null ? null : Timestamp.fromDate(publishedAt!),
  };
}

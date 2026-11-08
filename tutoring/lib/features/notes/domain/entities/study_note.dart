import 'package:tutoring/features/notes/domain/entities/note_status.dart';

class StudyNote {
  const StudyNote({
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
  final NoteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  String get weekLabel => 'W${week.toString().padLeft(2, '0')}';

  StudyNote copyWith({
    String? id,
    String? classId,
    String? title,
    String? summary,
    int? week,
    String? authorId,
    NoteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) => StudyNote(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    week: week ?? this.week,
    authorId: authorId ?? this.authorId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
  );
}


List<StudyNote> publishedNotes(Iterable<StudyNote> notes) => notes
    .where((note) => note.status == NoteStatus.published)
    .toList(growable: false);

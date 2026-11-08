import 'package:tutoring/features/notes/domain/entities/study_note.dart';

/// Neighbours of a note in reading order; null at either end.
typedef AdjacentNotes = ({StudyNote? previous, StudyNote? next});

/// Reading order of a class: week ascending, then publish time, then title.
/// The notes list shows the newest week first; the reader walks the other
/// way so "다음 섹션" moves forward through the course.
List<StudyNote> notesInReadingOrder(Iterable<StudyNote> notes) {
  final ordered = notes.toList(growable: false);
  ordered.sort((a, b) {
    final byWeek = a.week.compareTo(b.week);
    if (byWeek != 0) return byWeek;
    final byTime = (a.publishedAt ?? a.createdAt).compareTo(
      b.publishedAt ?? b.createdAt,
    );
    if (byTime != 0) return byTime;
    return a.title.compareTo(b.title);
  });
  return ordered;
}

/// Previous and next note around [currentId]. Both are null when the note is
/// not in [notes] (for example a draft opened by its author).
AdjacentNotes adjacentNotes(Iterable<StudyNote> notes, String currentId) {
  final ordered = notesInReadingOrder(notes);
  final index = ordered.indexWhere((note) => note.id == currentId);
  if (index < 0) return (previous: null, next: null);
  return (
    previous: index > 0 ? ordered[index - 1] : null,
    next: index + 1 < ordered.length ? ordered[index + 1] : null,
  );
}

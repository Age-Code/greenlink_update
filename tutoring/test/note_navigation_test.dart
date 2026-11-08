import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_navigation.dart';

StudyNote _note(String id, int week, {DateTime? publishedAt}) {
  final now = DateTime(2026, 11, 1);
  return StudyNote(
    id: id,
    classId: 'class-1',
    title: id,
    summary: '',
    week: week,
    authorId: 'tutor-1',
    status: NoteStatus.published,
    createdAt: now,
    updatedAt: now,
    publishedAt: publishedAt ?? now,
  );
}

void main() {
  test(
    'reading order is week ascending even when the list is newest first',
    () {
      final notes = [_note('c', 3), _note('a', 1), _note('b', 2)];

      expect(notesInReadingOrder(notes).map((note) => note.id), [
        'a',
        'b',
        'c',
      ]);
    },
  );

  test('same week falls back to publish time', () {
    final early = _note('early', 2, publishedAt: DateTime(2026, 11, 2));
    final late = _note('late', 2, publishedAt: DateTime(2026, 11, 5));

    expect(notesInReadingOrder([late, early]).map((note) => note.id), [
      'early',
      'late',
    ]);
  });

  test('adjacentNotes returns the neighbours in reading order', () {
    final notes = [_note('c', 3), _note('a', 1), _note('b', 2)];

    final middle = adjacentNotes(notes, 'b');
    expect(middle.previous?.id, 'a');
    expect(middle.next?.id, 'c');

    final first = adjacentNotes(notes, 'a');
    expect(first.previous, isNull);
    expect(first.next?.id, 'b');

    final last = adjacentNotes(notes, 'c');
    expect(last.previous?.id, 'b');
    expect(last.next, isNull);
  });

  test('adjacentNotes has no neighbours for a note outside the list', () {
    final result = adjacentNotes([_note('a', 1)], 'draft');

    expect(result.previous, isNull);
    expect(result.next, isNull);
  });
}

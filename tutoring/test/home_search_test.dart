import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/home/presentation/controllers/home_search.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';

import 'helpers/fake_repositories.dart';

void main() {
  final classes = [
    sampleClass(),
    sampleClass(id: 'class-2', title: '자료구조 스터디'),
  ];
  final notesByClass = {
    'class-1': [sampleNote(id: 'note-2', week: 2)],
    'class-2': [
      sampleNote(
        id: 'tree',
        week: 1,
        classId: 'class-2',
      ).copyWith(title: 'Tree & Graph'),
      sampleNote(
        id: 'hidden',
        week: 2,
        classId: 'class-2',
        status: NoteStatus.draft,
      ).copyWith(title: '자료구조 초안'),
    ],
  };

  test('empty query has no results', () {
    expect(searchHome('   ', classes, notesByClass), isEmpty);
  });

  test('classes come first, then notes, matched case-insensitively', () {
    final results = searchHome('tree', classes, notesByClass);
    expect(results.single.isNote, isTrue);
    expect(results.single.title, 'Tree & Graph');
    expect(results.single.subtitle, '자료구조 스터디 · Week 01');

    final mixed = searchHome('자료구조', classes, notesByClass);
    expect(mixed.first.isNote, isFalse);
    expect(mixed.first.title, '자료구조 스터디');
    // The caller passes published notes only; a draft given anyway is
    // still just text to match, so it shows up here.
    expect(mixed.map((result) => result.title), contains('자료구조 초안'));
  });

  test('a class without notes still matches by its own title', () {
    final results = searchHome('파이썬', classes, const {});
    expect(results.single.studyClass.id, 'class-1');
    expect(results.single.subtitle, 'Tutor · 김튜터');
  });
}

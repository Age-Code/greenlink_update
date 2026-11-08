import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/notes/data/dtos/annotation_dto.dart';
import 'package:tutoring/features/notes/data/dtos/note_dto.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/domain/repositories/annotation_repository.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';

void main() {
  group('note mapping and filtering', () {
    test('NoteDto converts Firestore values to a domain note', () {
      final now = DateTime.utc(2026, 11, 4);
      final note = NoteDto.fromMap('note-1', {
        'classId': 'class-1',
        'title': 'Dictionary',
        'summary': 'key-value basics',
        'week': 5,
        'authorId': 'tutor-1',
        'status': 'published',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'publishedAt': Timestamp.fromDate(now),
      }).toDomain();

      expect(note.id, 'note-1');
      expect(note.weekLabel, 'W05');
      expect(note.status, NoteStatus.published);
      expect(note.createdAt.toUtc(), now);
    });

    test('publishedNotes removes drafts', () {
      final notes = [
        _note(id: 'draft', status: NoteStatus.draft),
        _note(id: 'published', status: NoteStatus.published),
      ];

      expect(publishedNotes(notes).map((note) => note.id), ['published']);
    });
  });

  test('AnnotationDto round-trips through the domain model', () {
    final now = DateTime.utc(2026, 11, 4);
    final annotation = AnnotationDto.fromMap('annotation-1', {
      'userId': 'user-1',
      'classId': 'class-1',
      'noteId': 'note-1',
      'blockId': 'block-1',
      'type': 'highlight',
      'content': '',
      'selectedText': 'Dictionary',
      'startOffset': 0,
      'endOffset': 10,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }).toDomain();

    final dto = AnnotationDto.fromDomain(annotation);
    expect(dto.type, 'highlight');
    expect(dto.selectedText, 'Dictionary');
    expect(dto.endOffset, 10);
  });

  test('annotation controller creates, deletes, and toggles a bookmark', () async {
    final repository = _FakeAnnotationRepository();
    final container = ProviderContainer(
      overrides: [annotationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(annotationControllerProvider.future);
    final controller = container.read(annotationControllerProvider.notifier);

    expect(
      await controller.addMemo(
        userId: 'user-1',
        classId: 'class-1',
        noteId: 'note-1',
        blockId: null,
        content: 'remember this',
      ),
      isTrue,
    );
    expect(repository.items.single.type, AnnotationType.memo);

    final memo = repository.items.single;
    expect(await controller.deleteAnnotation(memo), isTrue);
    expect(repository.items, isEmpty);

    expect(
      await controller.toggleBookmark(
        userId: 'user-1',
        classId: 'class-1',
        noteId: 'note-1',
        bookmark: null,
      ),
      isTrue,
    );
    final bookmark = findBookmark(repository.items);
    expect(bookmark, isNotNull);

    expect(
      await controller.toggleBookmark(
        userId: 'user-1',
        classId: 'class-1',
        noteId: 'note-1',
        bookmark: bookmark,
      ),
      isTrue,
    );
    expect(repository.items, isEmpty);
  });
}

StudyNote _note({required String id, required NoteStatus status}) {
  final now = DateTime.utc(2026, 11, 4);
  return StudyNote(
    id: id,
    classId: 'class-1',
    title: id,
    summary: '',
    week: 1,
    authorId: 'tutor-1',
    status: status,
    createdAt: now,
    updatedAt: now,
    publishedAt: status == NoteStatus.published ? now : null,
  );
}

class _FakeAnnotationRepository implements AnnotationRepository {
  @override
  Future<void> deleteAllForUser(String userId) async {
    items.removeWhere((item) => item.userId == userId);
  }

  final List<StudyAnnotation> items = [];
  var _nextId = 0;

  @override
  Stream<List<StudyAnnotation>> watchAnnotations({
    required String userId,
    required String noteId,
  }) => Stream.value(
    items.where((item) => item.noteId == noteId).toList(growable: false),
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
  }) async {
    final now = DateTime.utc(2026, 11, 4);
    final annotation = StudyAnnotation(
      id: 'annotation-${_nextId++}',
      userId: userId,
      classId: classId,
      noteId: noteId,
      blockId: blockId,
      type: type,
      content: content,
      selectedText: selectedText,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: now,
      updatedAt: now,
    );
    items.add(annotation);
    return annotation;
  }

  @override
  Future<void> deleteAnnotation({
    required String userId,
    required String annotationId,
  }) async {
    items.removeWhere(
      (item) => item.userId == userId && item.id == annotationId,
    );
  }

  @override
  Future<void> updateAnnotation(StudyAnnotation annotation) async {
    final index = items.indexWhere((item) => item.id == annotation.id);
    if (index >= 0) items[index] = annotation;
  }

  @override
  Future<void> saveAnnotation(StudyAnnotation annotation) async {
    final index = items.indexWhere((item) => item.id == annotation.id);
    if (index >= 0) {
      items[index] = annotation;
    } else {
      items.add(annotation);
    }
  }
}

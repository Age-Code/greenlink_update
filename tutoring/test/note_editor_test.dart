import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/notes/data/dtos/quick_check_dto.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/domain/repositories/note_repository.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_editor_controller.dart';

void main() {
  test('note status transitions from draft to published and back', () {
    final now = DateTime(2026, 11, 5);
    final draft = StudyNote(
      id: 'note-1',
      classId: 'class-1',
      title: 'Dictionary',
      summary: '',
      week: 5,
      authorId: 'tutor-1',
      status: NoteStatus.draft,
      createdAt: now,
      updatedAt: now,
      publishedAt: null,
    );
    final published = draft.copyWith(
      status: NoteStatus.published,
      publishedAt: now,
    );
    final unpublished = published.copyWith(
      status: NoteStatus.draft,
      clearPublishedAt: true,
    );

    expect(published.status, NoteStatus.published);
    expect(published.publishedAt, now);
    expect(unpublished.status, NoteStatus.draft);
    expect(unpublished.publishedAt, isNull);
  });

  test('publish validation requires a title and meaningful block', () {
    final empty = NoteEditorState.initial(null);
    expect(empty.validationError(forPublish: true), isNotNull);

    final titled = empty.copyWith(title: 'Dictionary');
    expect(titled.validationError(forPublish: true), contains('블록'));

    final valid = titled.copyWith(
      blocks: const [
        NoteBlock(
          id: 'block-1',
          noteId: '',
          type: NoteBlockType.paragraph,
          order: 0,
          content: 'key-value 형태로 데이터를 저장합니다.',
          language: null,
        ),
      ],
    );
    expect(valid.validationError(forPublish: true), isNull);
  });

  test('Quick Check validation requires options, answer, and explanation', () {
    final now = DateTime(2026, 11, 5);
    final quickCheck = QuickCheck(
      quizId: 'quiz-1',
      questionId: 'question-1',
      classId: 'class-1',
      noteId: 'note-1',
      title: 'Quick Check',
      prompt: 'Dictionary의 안전한 조회 방법은?',
      options: const ['get()', 'remove()', 'sort()', 'append()'],
      correctOptionIndex: 0,
      explanation: 'get()은 key가 없어도 기본값을 반환할 수 있습니다.',
      createdBy: 'tutor-1',
      createdAt: now,
      updatedAt: now,
    );

    expect(quickCheck.isValid, isTrue);
    expect(quickCheck.copyWith(explanation: '').isValid, isFalse);
  });

  test('QuickCheckDto maps quiz and question documents', () {
    final now = DateTime.utc(2026, 11, 5);
    final dto = QuickCheckDto.fromFirestore(
      quizId: 'quiz-1',
      questionId: 'question-1',
      quiz: {
        'classId': 'class-1',
        'noteId': 'note-1',
        'title': 'Quick Check',
        'createdBy': 'tutor-1',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
      question: const {
        'prompt': '안전한 조회 방법은?',
        'options': ['get()', 'remove()', 'sort()', 'append()'],
        'correctOptionIndex': 0,
        'explanation': 'get()을 사용합니다.',
      },
    );

    expect(dto.toDomain().isValid, isTrue);
    expect(dto.questionToFirestore()['type'], 'multipleChoice');
  });

  test('editor keeps block order and saves through NoteRepository', () async {
    final repository = _FakeNoteRepository();
    final controller = NoteEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', noteId: null),
    );
    addTearDown(controller.dispose);

    controller.setTitle('Dictionary');
    final paragraph = controller.addBlock(NoteBlockType.paragraph);
    controller.updateBlockContent(paragraph, '본문');
    final heading = controller.addBlock(NoteBlockType.heading);
    controller.updateBlockContent(heading, '제목');
    controller.moveBlock(heading, -1);

    expect(controller.state.blocks.map((block) => block.id), [heading, paragraph]);
    expect(controller.state.blocks.map((block) => block.order), [0, 1]);

    final noteId = await controller.save(status: NoteStatus.published);
    expect(noteId, 'note-1');
    expect(repository.savedNote?.status, NoteStatus.published);
    expect(repository.savedBlocks.map((block) => block.order), [0, 1]);
  });

  test('slash-style block conversion keeps content and prepares a quiz', () {
    final repository = _FakeNoteRepository();
    final controller = NoteEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', noteId: null),
    );
    addTearDown(controller.dispose);

    final blockId = controller.addBlock(NoteBlockType.paragraph);
    controller.updateBlockContent(blockId, '핵심 개념');
    controller.updateBlockType(blockId, NoteBlockType.heading2);

    expect(controller.state.blocks.single.type, NoteBlockType.heading2);
    expect(controller.state.blocks.single.content, '핵심 개념');

    controller.updateBlockType(blockId, NoteBlockType.quiz);
    expect(controller.state.blocks.single.type, NoteBlockType.quiz);
    expect(controller.state.blocks.single.quizId, isNotNull);
    expect(controller.state.quickChecksByBlockId[blockId], isNotNull);
  });

  test('mid-block slash command keeps prior content in its original block', () {
    final repository = _FakeNoteRepository();
    final controller = NoteEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', noteId: null),
    );
    addTearDown(controller.dispose);

    final originalId = controller.addBlock(NoteBlockType.paragraph);
    controller.updateBlockContent(originalId, '기존 문단');
    final newId = controller.splitBlock(
      blockId: originalId,
      leadingContent: '기존 문단',
      trailingContent: 'print("hello")',
      newType: NoteBlockType.code,
    );

    expect(controller.state.blocks, hasLength(2));
    expect(controller.state.blocks.first.id, originalId);
    expect(controller.state.blocks.first.type, NoteBlockType.paragraph);
    expect(controller.state.blocks.first.content, '기존 문단');
    expect(controller.state.blocks.last.id, newId);
    expect(controller.state.blocks.last.type, NoteBlockType.code);
    expect(controller.state.blocks.last.content, 'print("hello")');
    expect(controller.state.blocks.map((block) => block.order), [0, 1]);
  });

  test('linking a quiz question stores references without copying a block model', () {
    final repository = _FakeNoteRepository();
    final controller = NoteEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', noteId: null),
    );
    addTearDown(controller.dispose);
    final blockId = controller.addBlock(NoteBlockType.quiz);
    final linked = controller.state.quickChecksByBlockId[blockId]!.copyWith(
      quizId: 'shared-quiz',
      questionId: 'shared-question',
      title: 'Dictionary Quiz',
      prompt: '안전한 조회 방법은?',
      options: const ['[]', 'get()', 'find()', 'value()'],
      correctOptionIndex: 1,
      explanation: 'get()을 사용합니다.',
    );

    controller.linkQuickCheck(blockId, linked);

    expect(controller.state.blocks.single.quizId, 'shared-quiz');
    expect(controller.state.blocks.single.questionId, 'shared-question');
    expect(controller.state.blocks.single.content, 'Dictionary Quiz');
  });
}

class _FakeNoteRepository implements NoteRepository {
  StudyNote? savedNote;
  List<NoteBlock> savedBlocks = [];

  @override
  Future<String> saveNote({
    required StudyNote note,
    required List<NoteBlock> blocks,
    required Map<String, QuickCheck> quickChecksByBlockId,
  }) async {
    savedNote = note;
    savedBlocks = blocks;
    return 'note-1';
  }

  @override
  Future<void> deleteNote(String classId, String noteId) async {}

  @override
  Future<List<NoteBlock>> getNoteBlocks(String classId, String noteId) async => [];

  @override
  Future<StudyNote?> getNote(String classId, String noteId) async => null;

  @override
  Future<StudyNote?> getNoteForAuthor(String classId, String noteId) async => null;

  @override
  Future<QuickCheck?> getQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) async => null;

  @override
  Future<void> setNoteStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  }) async {
    savedNote = savedNote?.copyWith(
      status: status,
      clearPublishedAt: status == NoteStatus.draft,
    );
  }

  @override
  Stream<List<StudyNote>> watchAllNotes(String classId) => const Stream.empty();

  @override
  Stream<QuickCheck?> watchQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) => const Stream.empty();

  @override
  Stream<List<NoteBlock>> watchNoteBlocks(String classId, String noteId) =>
      const Stream.empty();

  @override
  Stream<List<StudyNote>> watchPublishedNotes(String classId) =>
      const Stream.empty();
}

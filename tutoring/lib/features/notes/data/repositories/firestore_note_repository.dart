import 'package:tutoring/features/notes/data/data_sources/note_remote_data_source.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/domain/repositories/note_repository.dart';

class FirestoreNoteRepository implements NoteRepository {
  const FirestoreNoteRepository(this._remoteDataSource);

  final NoteRemoteDataSource _remoteDataSource;

  @override
  Stream<List<StudyNote>> watchPublishedNotes(String classId) =>
      _remoteDataSource.watchPublishedNotes(classId).map(
            (items) => items
                .map((item) => item.toDomain())
                .where((note) => note.status == NoteStatus.published)
                .toList(growable: false),
          );

  @override
  Stream<List<StudyNote>> watchAllNotes(String classId) =>
      _remoteDataSource.watchAllNotes(classId).map(
            (items) => items
                .map((item) => item.toDomain())
                .toList(growable: false),
          );

  @override
  Future<StudyNote?> getNote(String classId, String noteId) async {
    final dto = await _remoteDataSource.getNote(classId, noteId);
    final note = dto?.toDomain();
    return note?.status == NoteStatus.published ? note : null;
  }

  @override
  Future<StudyNote?> getNoteForAuthor(String classId, String noteId) async {
    return (await _remoteDataSource.getNote(classId, noteId))?.toDomain();
  }

  @override
  Future<List<NoteBlock>> getNoteBlocks(String classId, String noteId) async =>
      (await _remoteDataSource.getNoteBlocks(classId, noteId))
          .map((item) => item.toDomain())
          .toList(growable: false);

  @override
  Stream<List<NoteBlock>> watchNoteBlocks(String classId, String noteId) =>
      _remoteDataSource.watchNoteBlocks(classId, noteId).map(
            (items) => items
                .map((item) => item.toDomain())
                .toList(growable: false),
          );

  @override
  Future<QuickCheck?> getQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) async => (await _remoteDataSource.getQuickCheck(
    classId: classId,
    quizId: quizId,
    questionId: questionId,
  ))?.toDomain();

  @override
  Stream<QuickCheck?> watchQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  }) => _remoteDataSource.watchQuickCheck(
    classId: classId,
    quizId: quizId,
    questionId: questionId,
  ).map((item) => item?.toDomain());

  @override
  Future<String> saveNote({
    required StudyNote note,
    required List<NoteBlock> blocks,
    required Map<String, QuickCheck> quickChecksByBlockId,
  }) => _remoteDataSource.saveNote(
    note: note,
    blocks: blocks,
    quickChecksByBlockId: quickChecksByBlockId,
  );

  @override
  Future<void> setNoteStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  }) => _remoteDataSource.setNoteStatus(
    classId: classId,
    noteId: noteId,
    status: status,
  );

  @override
  Future<void> deleteNote(String classId, String noteId) =>
      _remoteDataSource.deleteNote(classId, noteId);
}

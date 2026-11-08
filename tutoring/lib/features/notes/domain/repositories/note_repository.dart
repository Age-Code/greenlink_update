import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

abstract interface class NoteRepository {
  Stream<List<StudyNote>> watchPublishedNotes(String classId);

  Stream<List<StudyNote>> watchAllNotes(String classId);

  Future<StudyNote?> getNote(String classId, String noteId);

  Future<StudyNote?> getNoteForAuthor(String classId, String noteId);

  Future<List<NoteBlock>> getNoteBlocks(String classId, String noteId);

  Stream<List<NoteBlock>> watchNoteBlocks(String classId, String noteId);

  Future<QuickCheck?> getQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  });

  Stream<QuickCheck?> watchQuickCheck({
    required String classId,
    required String quizId,
    required String questionId,
  });

  Future<String> saveNote({
    required StudyNote note,
    required List<NoteBlock> blocks,
    required Map<String, QuickCheck> quickChecksByBlockId,
  });

  Future<void> setNoteStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  });

  Future<void> deleteNote(String classId, String noteId);
}

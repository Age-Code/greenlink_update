import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/data/note_data_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_writer.dart';

export 'package:tutoring/features/notes/data/note_data_providers.dart'
    show annotationRepositoryProvider, noteRepositoryProvider;

typedef NoteKey = ({String classId, String noteId});
typedef AnnotationKey = ({String userId, String noteId});
typedef QuickCheckKey = ({String classId, String quizId, String questionId});

final publishedNotesProvider = StreamProvider.family<List<StudyNote>, String>((
  ref,
  classId,
) {
  return ref.watch(noteRepositoryProvider).watchPublishedNotes(classId);
});

final allNotesProvider = StreamProvider.family<List<StudyNote>, String>((
  ref,
  classId,
) {
  return ref.watch(noteRepositoryProvider).watchAllNotes(classId);
});

final noteProvider = FutureProvider.family<StudyNote?, NoteKey>((ref, key) {
  return ref.watch(noteRepositoryProvider).getNote(key.classId, key.noteId);
});

final noteBlocksProvider = StreamProvider.family<List<NoteBlock>, NoteKey>((
  ref,
  key,
) {
  return ref
      .watch(noteRepositoryProvider)
      .watchNoteBlocks(key.classId, key.noteId);
});

final quickCheckProvider = StreamProvider.family<QuickCheck?, QuickCheckKey>((
  ref,
  key,
) {
  return ref
      .watch(noteRepositoryProvider)
      .watchQuickCheck(
        classId: key.classId,
        quizId: key.quizId,
        questionId: key.questionId,
      );
});

final annotationsProvider =
    StreamProvider.family<List<StudyAnnotation>, AnnotationKey>((ref, key) {
      return ref
          .watch(annotationRepositoryProvider)
          .watchAnnotations(userId: key.userId, noteId: key.noteId);
    });

final annotationControllerProvider =
    AsyncNotifierProvider<AnnotationController, void>(AnnotationController.new);

final noteActionControllerProvider =
    AsyncNotifierProvider<NoteActionController, void>(NoteActionController.new);

class NoteActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setStatus({
    required String classId,
    required String noteId,
    required NoteStatus status,
  }) => _run(
    () => ref
        .read(noteRepositoryProvider)
        .setNoteStatus(classId: classId, noteId: noteId, status: status),
  );

  Future<String?> publishNote({
    required String classId,
    required String noteId,
  }) async {
    if (state.isLoading) return '다른 노트 작업이 진행 중이에요.';
    state = const AsyncLoading();
    try {
      final repository = ref.read(noteRepositoryProvider);
      final note = await repository.getNoteForAuthor(classId, noteId);
      final blocks = await repository.getNoteBlocks(classId, noteId);
      if (note == null || note.title.trim().isEmpty) {
        state = const AsyncData<void>(null);
        return '노트 제목을 입력해주세요.';
      }
      var meaningful = false;
      var hasInvalidQuickCheck = false;
      for (final block in blocks) {
        if (block.type == NoteBlockType.quiz &&
            block.quizId != null &&
            block.questionId != null) {
          final quickCheck = await repository.getQuickCheck(
            classId: classId,
            quizId: block.quizId!,
            questionId: block.questionId!,
          );
          if (quickCheck?.isValid ?? false) {
            meaningful = true;
          } else {
            hasInvalidQuickCheck = true;
          }
        } else if (block.content.trim().isNotEmpty) {
          meaningful = true;
        }
      }
      if (hasInvalidQuickCheck) {
        state = const AsyncData<void>(null);
        return 'Quick Check의 문제, 선택지, 정답, 해설을 확인해주세요.';
      }
      if (!meaningful) {
        state = const AsyncData<void>(null);
        return '내용이 있는 블록을 하나 이상 추가해주세요.';
      }
      await repository.setNoteStatus(
        classId: classId,
        noteId: noteId,
        status: NoteStatus.published,
      );
      await ref
          .read(notificationWriterProvider)
          .notePublished(
            classId: classId,
            noteId: noteId,
            noteTitle: note.title,
          );
      state = const AsyncData<void>(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return '노트를 게시하지 못했어요.';
    }
  }

  Future<bool> deleteNote({required String classId, required String noteId}) =>
      _run(() => ref.read(noteRepositoryProvider).deleteNote(classId, noteId));

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

class AnnotationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// [selectedText] is the sentence the memo was written from, if any.
  Future<bool> addMemo({
    required String userId,
    required String classId,
    required String noteId,
    required String? blockId,
    required String content,
    String? selectedText,
  }) => _run(
    () => ref
        .read(annotationRepositoryProvider)
        .createAnnotation(
          userId: userId,
          classId: classId,
          noteId: noteId,
          blockId: blockId,
          type: AnnotationType.memo,
          content: content.trim(),
          selectedText: selectedText,
        ),
  );

  Future<bool> updateMemo(StudyAnnotation memo, {required String content}) =>
      _run(
        () => ref
            .read(annotationRepositoryProvider)
            .updateAnnotation(
              memo.copyWith(content: content.trim(), updatedAt: DateTime.now()),
            ),
      );

  Future<bool> toggleBookmark({
    required String userId,
    required String classId,
    required String noteId,
    required StudyAnnotation? bookmark,
  }) => _run(() async {
    final repository = ref.read(annotationRepositoryProvider);
    if (bookmark != null) {
      await repository.deleteAnnotation(
        userId: userId,
        annotationId: bookmark.id,
      );
    } else {
      await repository.createAnnotation(
        userId: userId,
        classId: classId,
        noteId: noteId,
        blockId: null,
        type: AnnotationType.bookmark,
        content: '',
      );
    }
  });

  Future<bool> toggleBlockHighlight({
    required String userId,
    required String classId,
    required String noteId,
    required NoteBlock block,
    required StudyAnnotation? highlight,
  }) => _run(() async {
    final repository = ref.read(annotationRepositoryProvider);
    if (highlight != null) {
      await repository.deleteAnnotation(
        userId: userId,
        annotationId: highlight.id,
      );
    } else {
      await repository.createAnnotation(
        userId: userId,
        classId: classId,
        noteId: noteId,
        blockId: block.id,
        type: AnnotationType.highlight,
        content: '',
        selectedText: block.content,
        startOffset: 0,
        endOffset: block.content.length,
      );
    }
  });

  Future<bool> deleteAnnotation(StudyAnnotation annotation) => _run(
    () => ref
        .read(annotationRepositoryProvider)
        .deleteAnnotation(
          userId: annotation.userId,
          annotationId: annotation.id,
        ),
  );

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
    });
    return !state.hasError;
  }
}

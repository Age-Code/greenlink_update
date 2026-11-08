import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/data/note_data_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/domain/repositories/note_repository.dart';

typedef NoteEditorArgs = ({
  String classId,
  String userId,
  String? noteId,
});

final noteEditorControllerProvider = StateNotifierProvider.autoDispose.family<
    NoteEditorController, NoteEditorState, NoteEditorArgs>((ref, args) {
  return NoteEditorController(
    repository: ref.watch(noteRepositoryProvider),
    args: args,
  );
});

class NoteEditorState {
  const NoteEditorState({
    required this.noteId,
    required this.title,
    required this.summary,
    required this.week,
    required this.status,
    required this.blocks,
    required this.quickChecksByBlockId,
    required this.createdAt,
    required this.publishedAt,
    required this.isLoading,
    required this.isDirty,
    required this.isSaving,
    required this.lastSavedAt,
    required this.errorMessage,
  });

  factory NoteEditorState.initial(String? noteId) => NoteEditorState(
    noteId: noteId,
    title: '',
    summary: '',
    week: 1,
    status: NoteStatus.draft,
    blocks: const [],
    quickChecksByBlockId: const {},
    createdAt: DateTime.now(),
    publishedAt: null,
    isLoading: noteId != null,
    isDirty: false,
    isSaving: false,
    lastSavedAt: null,
    errorMessage: null,
  );

  final String? noteId;
  final String title;
  final String summary;
  final int week;
  final NoteStatus status;
  final List<NoteBlock> blocks;
  final Map<String, QuickCheck> quickChecksByBlockId;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final bool isLoading;
  final bool isDirty;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String? errorMessage;

  bool get canPublish => validationError(forPublish: true) == null;

  String? validationError({required bool forPublish}) {
    if (title.trim().isEmpty) return '노트 제목을 입력해주세요.';
    if (!forPublish) return null;
    final meaningful = blocks.any((block) {
      if (block.type == NoteBlockType.quiz) {
        return quickChecksByBlockId[block.id]?.isValid ?? false;
      }
      return block.content.trim().isNotEmpty;
    });
    if (!meaningful) return '내용이 있는 블록을 하나 이상 추가해주세요.';
    for (final block in blocks.where((item) => item.type == NoteBlockType.quiz)) {
      if (!(quickChecksByBlockId[block.id]?.isValid ?? false)) {
        return 'Quick Check의 문제, 선택지, 정답, 해설을 확인해주세요.';
      }
    }
    return null;
  }

  NoteEditorState copyWith({
    String? noteId,
    String? title,
    String? summary,
    int? week,
    NoteStatus? status,
    List<NoteBlock>? blocks,
    Map<String, QuickCheck>? quickChecksByBlockId,
    DateTime? createdAt,
    DateTime? publishedAt,
    bool? isLoading,
    bool? isDirty,
    bool? isSaving,
    DateTime? lastSavedAt,
    String? errorMessage,
    bool clearError = false,
    bool clearPublishedAt = false,
  }) => NoteEditorState(
    noteId: noteId ?? this.noteId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    week: week ?? this.week,
    status: status ?? this.status,
    blocks: blocks ?? this.blocks,
    quickChecksByBlockId: quickChecksByBlockId ?? this.quickChecksByBlockId,
    createdAt: createdAt ?? this.createdAt,
    publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
    isLoading: isLoading ?? this.isLoading,
    isDirty: isDirty ?? this.isDirty,
    isSaving: isSaving ?? this.isSaving,
    lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class NoteEditorController extends StateNotifier<NoteEditorState> {
  NoteEditorController({required this.repository, required this.args})
      : super(NoteEditorState.initial(args.noteId)) {
    if (args.noteId != null) _load(args.noteId!);
  }

  final NoteRepository repository;
  final NoteEditorArgs args;

  /// Current editor state for screens, which may not read the protected
  /// `state` member directly.
  NoteEditorState get current => state;

  Future<void> _load(String noteId) async {
    try {
      final note = await repository.getNoteForAuthor(args.classId, noteId);
      final blocks = await repository.getNoteBlocks(args.classId, noteId);
      if (note == null) throw StateError('note not found');
      final quickChecks = <String, QuickCheck>{};
      for (final block in blocks.where((item) => item.type == NoteBlockType.quiz)) {
        if (block.quizId == null || block.questionId == null) continue;
        final quickCheck = await repository.getQuickCheck(
          classId: args.classId,
          quizId: block.quizId!,
          questionId: block.questionId!,
        );
        if (quickCheck != null) quickChecks[block.id] = quickCheck;
      }
      if (!mounted) return;
      state = state.copyWith(
        noteId: note.id,
        title: note.title,
        summary: note.summary,
        week: note.week,
        status: note.status,
        blocks: blocks,
        quickChecksByBlockId: quickChecks,
        createdAt: note.createdAt,
        publishedAt: note.publishedAt,
        isLoading: false,
        isDirty: false,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: '노트를 불러오지 못했어요.',
      );
    }
  }

  void setTitle(String value) => _edit(state.copyWith(title: value));
  void setSummary(String value) => _edit(state.copyWith(summary: value));
  void setWeek(int value) =>
      _edit(state.copyWith(week: value.clamp(1, 99).toInt()));

  String addBlock(NoteBlockType type) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final blockId = 'block-$stamp';
    final isQuiz = type == NoteBlockType.quiz;
    final block = NoteBlock(
      id: blockId,
      noteId: state.noteId ?? '',
      type: type,
      order: state.blocks.length,
      content: isQuiz ? 'Quick Check' : '',
      language: type == NoteBlockType.code ? 'python' : null,
      quizId: isQuiz ? 'quiz-$stamp' : null,
      questionId: isQuiz ? 'question-$stamp' : null,
    );
    final blocks = [...state.blocks, block];
    final quickChecks = {...state.quickChecksByBlockId};
    if (isQuiz) {
      final now = DateTime.now();
      quickChecks[blockId] = QuickCheck(
        quizId: block.quizId!,
        questionId: block.questionId!,
        classId: args.classId,
        noteId: state.noteId ?? '',
        title: 'Quick Check',
        prompt: '',
        options: const ['', '', '', ''],
        correctOptionIndex: -1,
        explanation: '',
        createdBy: args.userId,
        createdAt: now,
        updatedAt: now,
      );
    }
    _edit(state.copyWith(blocks: _normalize(blocks), quickChecksByBlockId: quickChecks));
    return blockId;
  }

  void updateBlockContent(String blockId, String content) {
    _edit(state.copyWith(
      blocks: state.blocks
          .map((block) => block.id == blockId ? block.copyWith(content: content) : block)
          .toList(growable: false),
    ));
  }

  void updateBlockType(String blockId, NoteBlockType type) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    NoteBlock? updatedBlock;
    final blocks = state.blocks.map((block) {
      if (block.id != blockId) return block;
      updatedBlock = block.copyWith(
        type: type,
        language: type == NoteBlockType.code
            ? block.language ?? 'dart'
            : block.language,
        quizId: type == NoteBlockType.quiz
            ? block.quizId ?? 'quiz-$stamp'
            : block.quizId,
        questionId: type == NoteBlockType.quiz
            ? block.questionId ?? 'question-$stamp'
            : block.questionId,
      );
      return updatedBlock!;
    }).toList(growable: false);
    final quickChecks = {...state.quickChecksByBlockId};
    if (type == NoteBlockType.quiz && updatedBlock != null) {
      final now = DateTime.now();
      quickChecks.putIfAbsent(
        blockId,
        () => QuickCheck(
          quizId: updatedBlock!.quizId!,
          questionId: updatedBlock!.questionId!,
          classId: args.classId,
          noteId: state.noteId ?? '',
          title: 'Quick Check',
          prompt: '',
          options: const ['', '', '', ''],
          correctOptionIndex: -1,
          explanation: '',
          createdBy: args.userId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      quickChecks.remove(blockId);
    }
    _edit(state.copyWith(blocks: blocks, quickChecksByBlockId: quickChecks));
  }

  String splitBlock({
    required String blockId,
    required String leadingContent,
    required String trailingContent,
    required NoteBlockType newType,
  }) {
    final index = state.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return blockId;

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final newBlockId = 'block-$stamp';
    final isQuiz = newType == NoteBlockType.quiz;
    final original = state.blocks[index];
    final newBlock = NoteBlock(
      id: newBlockId,
      noteId: state.noteId ?? '',
      type: newType,
      order: index + 1,
      content: trailingContent,
      language: newType == NoteBlockType.code ? 'dart' : null,
      quizId: isQuiz ? 'quiz-$stamp' : null,
      questionId: isQuiz ? 'question-$stamp' : null,
    );
    final blocks = [...state.blocks];
    blocks[index] = original.copyWith(content: leadingContent);
    blocks.insert(index + 1, newBlock);

    final quickChecks = {...state.quickChecksByBlockId};
    if (isQuiz) {
      final now = DateTime.now();
      quickChecks[newBlockId] = QuickCheck(
        quizId: newBlock.quizId!,
        questionId: newBlock.questionId!,
        classId: args.classId,
        noteId: state.noteId ?? '',
        title: 'Quick Check',
        prompt: '',
        options: const ['', '', '', ''],
        correctOptionIndex: -1,
        explanation: '',
        createdBy: args.userId,
        createdAt: now,
        updatedAt: now,
      );
    }
    _edit(
      state.copyWith(
        blocks: _normalize(blocks),
        quickChecksByBlockId: quickChecks,
      ),
    );
    return newBlockId;
  }

  void updateCodeLanguage(String blockId, String language) {
    _edit(state.copyWith(
      blocks: state.blocks
          .map((block) => block.id == blockId ? block.copyWith(language: language) : block)
          .toList(growable: false),
    ));
  }

  void updateQuickCheck(String blockId, QuickCheck quickCheck) {
    _edit(state.copyWith(
      quickChecksByBlockId: {
        ...state.quickChecksByBlockId,
        blockId: quickCheck.copyWith(updatedAt: DateTime.now()),
      },
    ));
  }

  void linkQuickCheck(String blockId, QuickCheck quickCheck) {
    _edit(
      state.copyWith(
        blocks: state.blocks
            .map(
              (block) => block.id == blockId
                  ? block.copyWith(
                      content: quickCheck.title,
                      quizId: quickCheck.quizId,
                      questionId: quickCheck.questionId,
                    )
                  : block,
            )
            .toList(growable: false),
        quickChecksByBlockId: {
          ...state.quickChecksByBlockId,
          blockId: quickCheck,
        },
      ),
    );
  }

  void removeBlock(String blockId) {
    final quickChecks = {...state.quickChecksByBlockId}..remove(blockId);
    _edit(state.copyWith(
      blocks: _normalize(
        state.blocks.where((block) => block.id != blockId).toList(),
      ),
      quickChecksByBlockId: quickChecks,
    ));
  }

  void moveBlock(String blockId, int direction) {
    final blocks = [...state.blocks];
    final index = blocks.indexWhere((block) => block.id == blockId);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= blocks.length) return;
    final item = blocks.removeAt(index);
    blocks.insert(target, item);
    _edit(state.copyWith(blocks: _normalize(blocks)));
  }

  Future<String?> save({NoteStatus? status}) async {
    final targetStatus = status ?? state.status;
    final error = state.validationError(
      forPublish: targetStatus == NoteStatus.published,
    );
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return null;
    }
    final now = DateTime.now();
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final note = StudyNote(
        id: state.noteId ?? '',
        classId: args.classId,
        title: state.title.trim(),
        summary: state.summary.trim(),
        week: state.week,
        authorId: args.userId,
        status: targetStatus,
        createdAt: state.createdAt,
        updatedAt: now,
        publishedAt: targetStatus == NoteStatus.published
            ? state.publishedAt ?? now
            : null,
      );
      final noteId = await repository.saveNote(
        note: note,
        blocks: _normalize(state.blocks),
        quickChecksByBlockId: state.quickChecksByBlockId,
      );
      if (!mounted) return noteId;
      state = state.copyWith(
        noteId: noteId,
        status: targetStatus,
        publishedAt: targetStatus == NoteStatus.published
            ? state.publishedAt ?? now
            : null,
        isSaving: false,
        isDirty: false,
        lastSavedAt: now,
        clearError: true,
        clearPublishedAt: targetStatus == NoteStatus.draft,
      );
      return noteId;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(
        isSaving: false,
        errorMessage: '저장하지 못했어요. 잠시 후 다시 시도해주세요.',
      );
      return null;
    }
  }

  void _edit(NoteEditorState next) {
    state = next.copyWith(isDirty: true, clearError: true);
  }

  List<NoteBlock> _normalize(List<NoteBlock> blocks) => [
    for (var index = 0; index < blocks.length; index++)
      blocks[index].copyWith(order: index),
  ];
}

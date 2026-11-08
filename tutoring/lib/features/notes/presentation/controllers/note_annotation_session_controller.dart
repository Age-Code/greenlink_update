import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';

enum NoteReaderMode { read, annotate }

enum AnnotationTool { pen, highlighter, text, eraser }

typedef AnnotationSessionKey = ({
  String userId,
  String classId,
  String noteId,
});

class NoteAnnotationSessionState {
  const NoteAnnotationSessionState({
    this.mode = NoteReaderMode.read,
    this.tool = AnnotationTool.pen,
    this.annotationsVisible = true,
    this.localChanges = const <String, StudyAnnotation>{},
    this.deletedIds = const <String>{},
    this.canUndo = false,
    this.canRedo = false,
    this.isSaving = false,
    this.strokeWidth = 2.6,
    this.colorValue = 0xFF5D4E49,
  });

  final NoteReaderMode mode;
  final AnnotationTool tool;
  final bool annotationsVisible;
  final Map<String, StudyAnnotation> localChanges;
  final Set<String> deletedIds;
  final bool canUndo;
  final bool canRedo;
  final bool isSaving;
  final double strokeWidth;
  final int colorValue;

  NoteAnnotationSessionState copyWith({
    NoteReaderMode? mode,
    AnnotationTool? tool,
    bool? annotationsVisible,
    Map<String, StudyAnnotation>? localChanges,
    Set<String>? deletedIds,
    bool? canUndo,
    bool? canRedo,
    bool? isSaving,
    double? strokeWidth,
    int? colorValue,
  }) => NoteAnnotationSessionState(
        mode: mode ?? this.mode,
        tool: tool ?? this.tool,
        annotationsVisible: annotationsVisible ?? this.annotationsVisible,
        localChanges: localChanges ?? this.localChanges,
        deletedIds: deletedIds ?? this.deletedIds,
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
        isSaving: isSaving ?? this.isSaving,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        colorValue: colorValue ?? this.colorValue,
      );

  List<StudyAnnotation> merge(List<StudyAnnotation> remote) {
    final merged = <String, StudyAnnotation>{
      for (final annotation in remote) annotation.id: annotation,
      ...localChanges,
    };
    for (final id in deletedIds) {
      merged.remove(id);
    }
    return merged.values.toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}

class _AnnotationEdit {
  const _AnnotationEdit({required this.before, required this.after});

  final StudyAnnotation? before;
  final StudyAnnotation? after;
}

class NoteAnnotationSessionController
    extends StateNotifier<NoteAnnotationSessionState> {
  NoteAnnotationSessionController(this.ref, this.key)
      : super(const NoteAnnotationSessionState());

  final Ref ref;
  final AnnotationSessionKey key;
  final List<_AnnotationEdit> _undo = <_AnnotationEdit>[];
  final List<_AnnotationEdit> _redo = <_AnnotationEdit>[];
  final Set<String> _dirtyIds = <String>{};
  final Set<String> _pendingDeletes = <String>{};
  Timer? _saveTimer;

  void setMode(NoteReaderMode mode) => state = state.copyWith(mode: mode);

  void setTool(AnnotationTool tool) => state = state.copyWith(tool: tool);

  void setStrokeWidth(double width) =>
      state = state.copyWith(strokeWidth: width);

  void setColor(int colorValue) => state = state.copyWith(colorValue: colorValue);

  void toggleVisibility() {
    final visible = !state.annotationsVisible;
    state = state.copyWith(
      annotationsVisible: visible,
      mode: visible ? state.mode : NoteReaderMode.read,
    );
  }

  void addStroke({
    required String blockId,
    required AnnotationStroke stroke,
    required AnnotationType type,
  }) {
    final now = DateTime.now();
    final annotation = StudyAnnotation(
      id: 'ink-${now.microsecondsSinceEpoch}',
      userId: key.userId,
      classId: key.classId,
      noteId: key.noteId,
      blockId: blockId,
      type: type,
      content: '',
      selectedText: null,
      startOffset: null,
      endOffset: null,
      createdAt: now,
      updatedAt: now,
      strokes: <AnnotationStroke>[stroke],
    );
    _applyEdit(_AnnotationEdit(before: null, after: annotation));
  }

  void addText({
    required String blockId,
    required String content,
    required double x,
    required double y,
  }) {
    final now = DateTime.now();
    final annotation = StudyAnnotation(
      id: 'text-${now.microsecondsSinceEpoch}',
      userId: key.userId,
      classId: key.classId,
      noteId: key.noteId,
      blockId: blockId,
      type: AnnotationType.text,
      content: content.trim(),
      selectedText: null,
      startOffset: null,
      endOffset: null,
      createdAt: now,
      updatedAt: now,
      positionX: x.clamp(0, 1).toDouble(),
      positionY: y.clamp(0, 1).toDouble(),
    );
    _applyEdit(_AnnotationEdit(before: null, after: annotation));
  }

  void updateText(
    StudyAnnotation annotation, {
    String? content,
    double? x,
    double? y,
  }) {
    final updated = annotation.copyWith(
      content: content,
      positionX: x?.clamp(0, 1).toDouble(),
      positionY: y?.clamp(0, 1).toDouble(),
      updatedAt: DateTime.now(),
    );
    _applyEdit(_AnnotationEdit(before: annotation, after: updated));
  }

  void delete(StudyAnnotation annotation) {
    _applyEdit(_AnnotationEdit(before: annotation, after: null));
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    final edit = _undo.removeLast();
    _redo.add(edit);
    await _applyWithoutHistory(edit.before, removed: edit.after);
    _updateHistoryState();
  }

  Future<void> redo() async {
    if (_redo.isEmpty) return;
    final edit = _redo.removeLast();
    _undo.add(edit);
    await _applyWithoutHistory(edit.after, removed: edit.before);
    _updateHistoryState();
  }

  void _applyEdit(_AnnotationEdit edit) {
    _undo.add(edit);
    _redo.clear();
    _applyLocal(edit.after, removed: edit.before);
    if (edit.after == null && edit.before != null) {
      _dirtyIds.remove(edit.before!.id);
      _pendingDeletes.add(edit.before!.id);
    } else if (edit.after != null) {
      _dirtyIds.add(edit.after!.id);
      _pendingDeletes.remove(edit.after!.id);
    }
    _updateHistoryState();
    _scheduleSave();
  }

  void _applyLocal(StudyAnnotation? value, {StudyAnnotation? removed}) {
    final changes = Map<String, StudyAnnotation>.from(state.localChanges);
    final deleted = Set<String>.from(state.deletedIds);
    if (removed != null && value == null) {
      changes.remove(removed.id);
      deleted.add(removed.id);
    } else if (value != null) {
      changes[value.id] = value;
      deleted.remove(value.id);
    }
    state = state.copyWith(localChanges: changes, deletedIds: deleted);
  }

  Future<void> _applyWithoutHistory(
    StudyAnnotation? value, {
    StudyAnnotation? removed,
  }) async {
    _applyLocal(value, removed: removed);
    final repository = ref.read(annotationRepositoryProvider);
    if (value == null && removed != null) {
      await repository.deleteAnnotation(
        userId: removed.userId,
        annotationId: removed.id,
      );
    } else if (value != null) {
      await repository.saveAnnotation(value);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), _flush);
  }

  Future<void> _flush() async {
    if (!mounted) return;
    state = state.copyWith(isSaving: true);
    final repository = ref.read(annotationRepositoryProvider);
    final deletes = Set<String>.from(_pendingDeletes);
    final saves = <StudyAnnotation>[];
    for (final id in _dirtyIds) {
      final annotation = state.localChanges[id];
      if (annotation != null) saves.add(annotation);
    }
    _pendingDeletes.removeAll(deletes);
    _dirtyIds.removeAll(saves.map((annotation) => annotation.id));
    try {
      for (final id in deletes) {
        await repository.deleteAnnotation(userId: key.userId, annotationId: id);
      }
      for (final annotation in saves) {
        await repository.saveAnnotation(annotation);
      }
    } catch (_) {
      _pendingDeletes.addAll(deletes);
      _dirtyIds.addAll(saves.map((annotation) => annotation.id));
      _saveTimer = Timer(const Duration(seconds: 2), _flush);
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  void _updateHistoryState() => state = state.copyWith(
        canUndo: _undo.isNotEmpty,
        canRedo: _redo.isNotEmpty,
      );

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final noteAnnotationSessionProvider = StateNotifierProvider.family<
    NoteAnnotationSessionController,
    NoteAnnotationSessionState,
    AnnotationSessionKey>((ref, key) {
  return NoteAnnotationSessionController(ref, key);
});

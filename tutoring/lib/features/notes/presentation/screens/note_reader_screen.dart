import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/format/relative_time.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_annotation_session_controller.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_navigation.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_progress.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/notes/presentation/services/note_pdf_export_service.dart';
import 'package:tutoring/features/notes/presentation/widgets/block_annotation_surface.dart';
import 'package:tutoring/features/notes/presentation/widgets/note_reader_footer.dart';
import 'package:tutoring/features/notes/presentation/widgets/reader_selection_toolbar.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quick_check_solver.dart';

/// Focus-mode reader for one published note (Figma 06_Note_Reader): a 720
/// column, no class menu, previous / next note in the footer and ←/→ keys.
class NoteReaderScreen extends ConsumerWidget {
  const NoteReaderScreen({
    super.key,
    required this.classId,
    required this.noteId,
    this.targetBlockId,
  });

  final String classId;
  final String noteId;
  final String? targetBlockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final key = (classId: classId, noteId: noteId);
    final note = ref.watch(noteProvider(key));
    final blocks = ref.watch(noteBlocksProvider(key));
    final annotations = ref.watch(
      annotationsProvider((userId: user.uid, noteId: noteId)),
    );
    final sessionKey = (userId: user.uid, classId: classId, noteId: noteId);
    final session = ref.watch(noteAnnotationSessionProvider(sessionKey));
    final remoteAnnotations =
        annotations.asData?.value ?? const <StudyAnnotation>[];
    final annotationItems = session.merge(remoteAnnotations);
    final bookmark = findBookmark(annotationItems);
    final actionState = ref.watch(annotationControllerProvider);
    final studyClass = ref.watch(studyClassProvider(classId)).asData?.value;
    final neighbours = adjacentNotes(
      ref.watch(publishedNotesProvider(classId)).asData?.value ??
          const <StudyNote>[],
      noteId,
    );
    final attempts =
        ref.watch(quizAttemptsProvider(user.uid)).asData?.value ??
        const <QuizAttempt>[];
    final progress = quickCheckProgress(
      blocks.asData?.value ?? const <NoteBlock>[],
      attempts,
    );
    final actionDisabled = actionState.isLoading || !annotations.hasValue;

    ref.listen(annotationControllerProvider, (_, next) {
      next.whenOrNull(
        error:
            (_, _) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('개인 학습 기록을 저장하지 못했어요.')),
            ),
      );
    });

    void openNote(StudyNote target) =>
        context.pushReplacement(AppRoutes.noteReader(classId, target.id));

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.classNotes(classId));
      }
    }

    void toggleBookmark() => ref
        .read(annotationControllerProvider.notifier)
        .toggleBookmark(
          userId: user.uid,
          classId: classId,
          noteId: noteId,
          bookmark: bookmark,
        );

    final sessionController = ref.read(
      noteAnnotationSessionProvider(sessionKey).notifier,
    );

    return AppResponsiveScaffold(
      maxWidth: AppLayout.readingMaxWidth,
      leading: _BackToNotesButton(
        showLabel: context.screenType != ScreenType.mobile,
        onPressed: goBack,
      ),
      actions: [
        IconButton(
          tooltip: bookmark == null ? '북마크 저장' : '북마크 제거',
          onPressed: actionDisabled ? null : toggleBookmark,
          icon: Icon(
            bookmark == null ? Icons.bookmark_border : Icons.bookmark,
            color:
                bookmark == null
                    ? AppColors.textSecondary
                    : AppColors.coralDark,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: '더보기',
          onSelected: (value) async {
            if (value == 'mode') {
              if (session.mode == NoteReaderMode.annotate) {
                sessionController.setMode(NoteReaderMode.read);
              } else {
                if (!session.annotationsVisible) {
                  sessionController.toggleVisibility();
                }
                sessionController.setMode(NoteReaderMode.annotate);
              }
            } else if (value == 'annotations') {
              _showAnnotationSummary(context, annotationItems);
            } else if (value == 'visibility') {
              sessionController.toggleVisibility();
            } else if (value == 'pdf-personal' || value == 'pdf-tutor') {
              final studyNote = note.asData?.value;
              final noteBlocks = blocks.asData?.value;
              if (studyNote == null || noteBlocks == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('노트를 모두 불러온 뒤 다시 시도해주세요.')),
                );
                return;
              }
              try {
                await const NotePdfExportService().export(
                  note: studyNote,
                  classTitle: studyClass?.title ?? 'Tugether',
                  blocks: noteBlocks,
                  annotations: annotationItems,
                  includePersonalAnnotations: value == 'pdf-personal',
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF를 만들지 못했어요. 다시 시도해주세요.')),
                  );
                }
              }
            }
          },
          itemBuilder:
              (_) => [
                PopupMenuItem(
                  value: 'mode',
                  child: Text(
                    session.mode == NoteReaderMode.annotate
                        ? '필기 모드 끝내기'
                        : '필기 모드',
                  ),
                ),
                const PopupMenuItem(
                  value: 'annotations',
                  child: Text('내 학습 기록 보기'),
                ),
                PopupMenuItem(
                  value: 'visibility',
                  child: Text(
                    session.annotationsVisible ? '내 필기 숨기기' : '내 필기 보이기',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'pdf-personal',
                  child: Text('PDF · 튜터 노트 + 내 필기'),
                ),
                const PopupMenuItem(
                  value: 'pdf-tutor',
                  child: Text('PDF · 튜터 노트만'),
                ),
              ],
        ),
      ],
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (neighbours.previous != null)
            const SingleActivator(LogicalKeyboardKey.arrowLeft):
                () => openNote(neighbours.previous!),
          if (neighbours.next != null)
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                () => openNote(neighbours.next!),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              if (session.mode == NoteReaderMode.annotate)
                _AnnotationToolbar(sessionKey: sessionKey, state: session),
              if (annotations.isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.coral,
                  backgroundColor: AppColors.coralSoft,
                ),
              if (annotations.hasError)
                MaterialBanner(
                  content: const Text('내 학습 기록을 불러오지 못했어요.'),
                  actions: [
                    TextButton(
                      onPressed:
                          () => ref.invalidate(
                            annotationsProvider((
                              userId: user.uid,
                              noteId: noteId,
                            )),
                          ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              Expanded(
                child: note.when(
                  loading: () => const _ReaderLoading(),
                  error:
                      (_, _) => _ReaderError(
                        onRetry: () => ref.invalidate(noteProvider(key)),
                      ),
                  data: (studyNote) {
                    if (studyNote == null) {
                      return const Center(child: Text('공개된 노트를 찾을 수 없어요.'));
                    }
                    return blocks.when(
                      loading: () => const _ReaderLoading(),
                      error:
                          (_, _) => _ReaderError(
                            onRetry:
                                () => ref.invalidate(noteBlocksProvider(key)),
                          ),
                      data:
                          (items) => _ReaderDocument(
                            studyNote: studyNote,
                            classTitle: studyClass?.title ?? 'Tugether',
                            blocks: items,
                            annotations: annotationItems,
                            progress: progress,
                            neighbours: neighbours,
                            onOpenNote: openNote,
                            bookmarked: bookmark != null,
                            onToggleBookmark:
                                actionDisabled ? null : toggleBookmark,
                            userId: user.uid,
                            classId: classId,
                            noteId: noteId,
                            actionDisabled: actionDisabled,
                            sessionKey: sessionKey,
                            session: session,
                            targetBlockId: targetBlockId,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-bar leading: back arrow with the "노트 목록" label from Figma 06. The
/// label is dropped on mobile so the note title keeps its room.
class _BackToNotesButton extends StatelessWidget {
  const _BackToNotesButton({required this.showLabel, required this.onPressed});

  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return IconButton(
        tooltip: '노트 목록으로 돌아가기',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.homeMuted,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: .3,
        ),
      ),
      icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.homeInk),
      label: const Text('노트 목록'),
    );
  }
}

class _AnnotationToolbar extends ConsumerWidget {
  const _AnnotationToolbar({required this.sessionKey, required this.state});

  final AnnotationSessionKey sessionKey;
  final NoteAnnotationSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      noteAnnotationSessionProvider(sessionKey).notifier,
    );
    return Material(
      color: AppColors.softGray,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.horizontalPaddingFor(context.screenType),
          vertical: 8,
        ),
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.edit_outlined,
              label: '펜',
              selected: state.tool == AnnotationTool.pen,
              onPressed: () => controller.setTool(AnnotationTool.pen),
            ),
            _ToolButton(
              icon: Icons.brush_outlined,
              label: '형광펜',
              selected: state.tool == AnnotationTool.highlighter,
              onPressed: () => controller.setTool(AnnotationTool.highlighter),
            ),
            _ToolButton(
              icon: Icons.text_fields,
              label: '텍스트',
              selected: state.tool == AnnotationTool.text,
              onPressed: () => controller.setTool(AnnotationTool.text),
            ),
            _ToolButton(
              icon: Icons.auto_fix_normal_outlined,
              label: '지우개',
              selected: state.tool == AnnotationTool.eraser,
              onPressed: () => controller.setTool(AnnotationTool.eraser),
            ),
            PopupMenuButton<double>(
              tooltip: '선 굵기',
              onSelected: controller.setStrokeWidth,
              icon: const Icon(Icons.line_weight),
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 1.6, child: Text('얇게')),
                    PopupMenuItem(value: 2.6, child: Text('보통')),
                    PopupMenuItem(value: 4.2, child: Text('굵게')),
                  ],
            ),
            for (final color in const <int>[
              0xFF5D4E49,
              0xFFEE8A68,
              0xFF6F8B65,
              0xFFF2C94C,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.setColor(color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            state.colorValue == color
                                ? AppColors.homeInk
                                : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const SizedBox(height: 26, child: VerticalDivider()),
            IconButton(
              tooltip: '실행 취소',
              onPressed: state.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: '다시 실행',
              onPressed: state.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: state.annotationsVisible ? '필기 숨기기' : '필기 보이기',
              onPressed: controller.toggleVisibility,
              icon: Icon(
                state.annotationsVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            if (state.isSaving) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 6),
              const Text('저장 중', style: TextStyle(fontSize: 11)),
            ],
            const SizedBox(height: 26, child: VerticalDivider()),
            IconButton(
              tooltip: '필기 모드 끝내기',
              onPressed: () => controller.setMode(NoteReaderMode.read),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
            selected ? AppColors.coralDark : AppColors.textSecondary,
        backgroundColor: selected ? AppColors.coralSoft : Colors.white,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    ),
  );
}

class _ReaderDocument extends ConsumerWidget {
  const _ReaderDocument({
    required this.studyNote,
    required this.classTitle,
    required this.blocks,
    required this.annotations,
    required this.progress,
    required this.neighbours,
    required this.onOpenNote,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.userId,
    required this.classId,
    required this.noteId,
    required this.actionDisabled,
    required this.sessionKey,
    required this.session,
    required this.targetBlockId,
  });

  final StudyNote studyNote;
  final String classTitle;
  final List<NoteBlock> blocks;
  final List<StudyAnnotation> annotations;

  /// Quick Check completion, 0..1; null hides the badge.
  final double? progress;
  final AdjacentNotes neighbours;
  final ValueChanged<StudyNote> onOpenNote;
  final bool bookmarked;
  final VoidCallback? onToggleBookmark;
  final String userId;
  final String classId;
  final String noteId;
  final bool actionDisabled;
  final AnnotationSessionKey sessionKey;
  final NoteAnnotationSessionState session;
  final String? targetBlockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedAnnotations =
        session.annotationsVisible
            ? annotations
            : annotations
                .where(
                  (annotation) => annotation.type == AnnotationType.bookmark,
                )
                .toList(growable: false);
    final noteMemos = displayedAnnotations
        .where(
          (annotation) =>
              annotation.type == AnnotationType.memo &&
              annotation.blockId == null,
        )
        .toList(growable: false);
    return AppPageBody(
      children: [
        _MetaRow(
          classTitle: classTitle,
          week: studyNote.week,
          progress: progress,
        ),
        const SizedBox(height: 8),
        Text(
          studyNote.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            height: 1.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -.9,
          ),
        ),
        if (studyNote.summary.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            studyNote.summary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1.65,
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 56),
            child: Text(
              '이 노트에는 아직 본문이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (final block in blocks)
            _buildBlock(context, ref, block, displayedAnnotations),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: actionDisabled ? null : () => _addMemo(context, ref, null),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.homeBrown,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.edit_note, size: 20),
          label: const Text('내 필기 추가'),
        ),
        if (noteMemos.isNotEmpty) ...[
          const SizedBox(height: 18),
          for (final memo in noteMemos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemoCard(
                memo: memo,
                onEdit:
                    actionDisabled ? null : () => _editMemo(context, ref, memo),
                onAddMemo:
                    actionDisabled ? null : () => _addMemo(context, ref, null),
              ),
            ),
        ],
        NoteReaderFooter(
          previous: neighbours.previous,
          next: neighbours.next,
          onOpen: onOpenNote,
        ),
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    WidgetRef ref,
    NoteBlock block,
    List<StudyAnnotation> displayedAnnotations,
  ) {
    final rendered = _BlockRenderer(
      block: block,
      classId: classId,
      noteId: noteId,
      annotations: displayedAnnotations,
      disabled: actionDisabled,
      bookmarked: bookmarked,
      onToggleBookmark: onToggleBookmark,
      onHighlight: () => _toggleHighlight(ref, block),
      onAddMemo:
          (selectedText) =>
              _addMemo(context, ref, block.id, selectedText: selectedText),
      onEditMemo: (memo) => _editMemo(context, ref, memo),
      sessionKey: sessionKey,
      readerMode: session.mode,
      annotationTool: session.tool,
      annotationsVisible: session.annotationsVisible,
    );
    if (targetBlockId == null || block.id != targetBlockId) return rendered;
    return _RelatedBlockTarget(
      key: ValueKey('related-$targetBlockId'),
      child: rendered,
    );
  }

  Future<void> _toggleHighlight(WidgetRef ref, NoteBlock block) {
    return ref
        .read(annotationControllerProvider.notifier)
        .toggleBlockHighlight(
          userId: userId,
          classId: classId,
          noteId: noteId,
          block: block,
          highlight: findBlockHighlight(annotations, block.id),
        );
  }

  Future<void> _addMemo(
    BuildContext context,
    WidgetRef ref,
    String? blockId, {
    String? selectedText,
  }) async {
    final quote = selectedText?.trim();
    final edit = await _showMemoDialog(
      context,
      quote: quote == null || quote.isEmpty ? null : quote,
    );
    final content = edit?.content?.trim();
    if (content == null || content.isEmpty) return;
    await ref
        .read(annotationControllerProvider.notifier)
        .addMemo(
          userId: userId,
          classId: classId,
          noteId: noteId,
          blockId: blockId,
          content: content,
          selectedText: quote == null || quote.isEmpty ? null : quote,
        );
  }

  Future<void> _editMemo(
    BuildContext context,
    WidgetRef ref,
    StudyAnnotation memo,
  ) async {
    final edit = await _showMemoDialog(
      context,
      initial: memo.content,
      quote: memo.selectedText,
      canDelete: true,
    );
    if (edit == null) return;
    final controller = ref.read(annotationControllerProvider.notifier);
    if (edit.delete) {
      await controller.deleteAnnotation(memo);
      return;
    }
    final content = edit.content?.trim() ?? '';
    if (content.isEmpty || content == memo.content) return;
    await controller.updateMemo(memo, content: content);
  }
}

/// "클래스명 · Week 05 · [학습 진행률 85%]" above the title.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.classTitle,
    required this.week,
    required this.progress,
  });

  final String classTitle;
  final int week;
  final double? progress;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    runSpacing: 6,
    children: [
      Text(
        '$classTitle · Week ${week.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: .35,
        ),
      ),
      if (progress != null) ...[
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.border,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '학습 진행률 ${(progress! * 100).round()}%',
            style: const TextStyle(
              color: AppColors.homeSageDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    ],
  );
}

class _RelatedBlockTarget extends StatefulWidget {
  const _RelatedBlockTarget({super.key, required this.child});

  final Widget child;

  @override
  State<_RelatedBlockTarget> createState() => _RelatedBlockTargetState();
}

class _RelatedBlockTargetState extends State<_RelatedBlockTarget> {
  Timer? _highlightTimer;
  var _highlighted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  Future<void> _reveal() async {
    if (!mounted) return;
    setState(() => _highlighted = true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
        alignment: .16,
      );
      if (!mounted) return;
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _highlighted = false);
      });
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _highlighted ? AppColors.coralSoft : Colors.transparent,
      border: Border.all(
        color: _highlighted ? AppColors.coral : Colors.transparent,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: widget.child,
  );
}

class _BlockRenderer extends ConsumerWidget {
  const _BlockRenderer({
    required this.block,
    required this.classId,
    required this.noteId,
    required this.annotations,
    required this.disabled,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onHighlight,
    required this.onAddMemo,
    required this.onEditMemo,
    required this.sessionKey,
    required this.readerMode,
    required this.annotationTool,
    required this.annotationsVisible,
  });

  final NoteBlock block;
  final String classId;
  final String noteId;
  final List<StudyAnnotation> annotations;
  final bool disabled;
  final bool bookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback onHighlight;

  /// Opens the memo dialog, quoting the selected text when there is one.
  final ValueChanged<String?> onAddMemo;
  final ValueChanged<StudyAnnotation> onEditMemo;
  final AnnotationSessionKey sessionKey;
  final NoteReaderMode readerMode;
  final AnnotationTool annotationTool;
  final bool annotationsVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlight = findBlockHighlight(annotations, block.id);
    final memos = annotations
        .where(
          (annotation) =>
              annotation.type == AnnotationType.memo &&
              annotation.blockId == block.id,
        )
        .toList(growable: false);
    final sessionController = ref.read(
      noteAnnotationSessionProvider(sessionKey).notifier,
    );
    final content = switch (block.type) {
      NoteBlockType.heading => _HeadingBlock(block: block, level: 1),
      NoteBlockType.heading2 => _HeadingBlock(block: block, level: 2),
      NoteBlockType.heading3 => _HeadingBlock(block: block, level: 3),
      NoteBlockType.code => _CodeBlock(block: block),
      NoteBlockType.quiz => _QuickCheckBlock(
        classId: classId,
        noteId: noteId,
        block: block,
      ),
      NoteBlockType.quote => _QuoteBlock(block: block),
      NoteBlockType.callout => _CalloutBlock(block: block),
      NoteBlockType.image => _ImageBlock(block: block),
      NoteBlockType.paragraph => _ParagraphBlock(
        block: block,
        highlighted: highlight != null,
        bookmarked: bookmarked,
        onHighlight: disabled ? null : onHighlight,
        onMemo: disabled ? null : onAddMemo,
        onBookmark: onToggleBookmark,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlockAnnotationSurface(
            blockId: block.id,
            annotations: annotations,
            mode: readerMode,
            tool: annotationTool,
            visible: annotationsVisible,
            strokeWidth:
                ref
                    .watch(noteAnnotationSessionProvider(sessionKey))
                    .strokeWidth,
            colorValue:
                ref.watch(noteAnnotationSessionProvider(sessionKey)).colorValue,
            onAddStroke:
                (stroke, type) => sessionController.addStroke(
                  blockId: block.id,
                  stroke: stroke,
                  type: type,
                ),
            onAddText:
                (content, x, y) => sessionController.addText(
                  blockId: block.id,
                  content: content,
                  x: x,
                  y: y,
                ),
            onUpdateText: sessionController.updateText,
            onDelete: sessionController.delete,
            child: content,
          ),
          if (memos.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final memo in memos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemoCard(
                  memo: memo,
                  onEdit: disabled ? null : () => onEditMemo(memo),
                  onAddMemo: disabled ? null : () => onAddMemo(null),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.block, required this.level});

  final NoteBlock block;
  final int level;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: level == 1 ? 24 : 16),
    child: Text(
      block.content,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize:
            level == 1
                ? 28
                : level == 2
                ? 24
                : 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: -.12,
      ),
    ),
  );
}

/// Body text. Selecting a sentence shows the dark toolbar with 강조 · 메모 ·
/// 북마크 · 복사 (Figma 06); the whole paragraph is what gets highlighted,
/// as before. On desktop the toolbar also appears after a mouse drag, which
/// Flutter only does for touch by itself.
class _ParagraphBlock extends StatefulWidget {
  const _ParagraphBlock({
    required this.block,
    required this.highlighted,
    required this.bookmarked,
    required this.onHighlight,
    required this.onMemo,
    required this.onBookmark,
  });

  final NoteBlock block;
  final bool highlighted;
  final bool bookmarked;
  final VoidCallback? onHighlight;
  final ValueChanged<String?>? onMemo;
  final VoidCallback? onBookmark;

  @override
  State<_ParagraphBlock> createState() => _ParagraphBlockState();
}

class _ParagraphBlockState extends State<_ParagraphBlock> {
  final _textKey = GlobalKey();

  static const _style = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    height: 1.7,
    letterSpacing: .1,
  );

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    padding:
        widget.highlighted
            ? const EdgeInsets.symmetric(horizontal: 13, vertical: 9)
            : EdgeInsets.zero,
    decoration: BoxDecoration(
      color: widget.highlighted ? AppColors.coralSoft : Colors.transparent,
      border: Border.all(
        color: widget.highlighted ? AppColors.homePeach : Colors.transparent,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Listener(
      onPointerUp: _onPointerUp,
      child: SelectableText.rich(
        inlineCodeSpan(widget.block.content, style: _style),
        key: _textKey,
        contextMenuBuilder: _buildToolbar,
      ),
    ),
  );

  Widget _buildToolbar(BuildContext context, EditableTextState state) {
    final value = state.textEditingValue;
    final selected =
        value.selection.isValid ? value.selection.textInside(value.text) : '';
    void run(VoidCallback action) {
      state.hideToolbar();
      action();
    }

    return ReaderSelectionToolbar(
      anchors: state.contextMenuAnchors,
      items: [
        if (widget.onHighlight != null)
          ReaderToolbarItem(
            icon:
                widget.highlighted
                    ? Icons.format_color_reset_outlined
                    : Icons.border_color_outlined,
            label: widget.highlighted ? '강조 해제' : '강조',
            color: AppColors.coral,
            onPressed: () => run(widget.onHighlight!),
          ),
        if (widget.onMemo != null)
          ReaderToolbarItem(
            icon: Icons.chat_bubble_outline,
            label: '메모',
            onPressed: () => run(() => widget.onMemo!(selected)),
          ),
        if (widget.onBookmark != null)
          ReaderToolbarItem(
            icon: widget.bookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: widget.bookmarked ? '북마크 해제' : '북마크',
            onPressed: () => run(widget.onBookmark!),
          ),
        ReaderToolbarItem(
          icon: Icons.content_copy,
          label: '복사',
          onPressed: () => state.copySelection(SelectionChangedCause.toolbar),
        ),
      ],
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final editable = _findEditableText(_textKey.currentContext);
      if (editable == null) return;
      if (!editable.textEditingValue.selection.isCollapsed) {
        editable.showToolbar();
      }
    });
  }
}

/// The [EditableTextState] inside a [SelectableText]; it is not exposed.
EditableTextState? _findEditableText(BuildContext? context) {
  if (context == null) return null;
  EditableTextState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is EditableTextState) {
      found = element.state as EditableTextState;
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return found;
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.block});

  final NoteBlock block;

  @override
  Widget build(BuildContext context) {
    final language = block.language?.trim();
    final divider = Colors.white.withValues(alpha: .08);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.noteCode,
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  language == null || language.isEmpty ? 'code' : language,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _copy(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textFaint,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                icon: const Icon(Icons.copy_outlined, size: 13),
                label: const Text('코드 복사'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14, right: 8),
            child: Container(height: 1, color: divider),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectableText(
              block.content,
              style: const TextStyle(
                color: AppColors.background,
                fontFamily: monoFontFamily,
                fontFamilyFallback: monoFontFallback,
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: block.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('코드를 복사했어요.')));
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.block});

  final NoteBlock block;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: AppColors.coral, width: 3)),
    ),
    child: Text(
      block.content,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.7,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({required this.block});

  final NoteBlock block;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.noteMemo,
      border: Border.all(color: AppColors.homeDivider),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      block.content,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.7,
      ),
    ),
  );
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.block});

  final NoteBlock block;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.softGray,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        const Icon(Icons.image_outlined, color: AppColors.textFaint),
        const SizedBox(height: 8),
        Text(
          block.content,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// Soft coral inline Quick Check card (Figma 06); the question itself is the
/// shared [QuickCheckSolver].
class _QuickCheckBlock extends StatelessWidget {
  const _QuickCheckBlock({
    required this.classId,
    required this.noteId,
    required this.block,
  });

  final String classId;
  final String noteId;
  final NoteBlock block;

  @override
  Widget build(BuildContext context) {
    final hasReference = block.quizId != null && block.questionId != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.coralSoft.withValues(alpha: .7),
        border: Border.all(color: AppColors.coral.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Quick Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .6,
                  ),
                ),
              ),
              if (!hasReference) ...[
                const Spacer(),
                const Text(
                  '연결 없음',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (!hasReference)
            const Text(
              'Quick Check 참조가 없어요.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            QuickCheckSolver(
              classId: classId,
              quizId: block.quizId!,
              questionId: block.questionId!,
              noteId: noteId,
            ),
        ],
      ),
    );
  }
}

/// "내 메모" card (Figma 06): header with the write time, the quoted sentence
/// when the memo came from a selection, and the add / edit actions.
class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.onEdit,
    required this.onAddMemo,
  });

  final StudyAnnotation memo;
  final VoidCallback? onEdit;
  final VoidCallback? onAddMemo;

  @override
  Widget build(BuildContext context) {
    final quote = memo.selectedText?.trim();
    final smallButton = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(0, 32),
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        border: Border.all(color: AppColors.homePeach),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 16, color: AppColors.coralDark),
              const SizedBox(width: 6),
              const Text(
                '내 메모',
                style: TextStyle(
                  color: AppColors.coralDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
              const Spacer(),
              Text(
                '${relativeTimeLabel(memo.createdAt)} 작성',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (quote != null && quote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“$quote”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            memo.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: AppColors.homePeach.withValues(alpha: .6),
          ),
          Row(
            children: [
              TextButton(
                onPressed: onAddMemo,
                style: smallButton.copyWith(
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.coralDark,
                  ),
                ),
                child: const Text('+ 내 필기 추가'),
              ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: smallButton.copyWith(
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.textSecondary,
                  ),
                ),
                child: const Text('편집'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Result of the memo dialog: new text, or a delete request.
class _MemoEdit {
  const _MemoEdit.save(this.content) : delete = false;
  const _MemoEdit.delete() : content = null, delete = true;

  final String? content;
  final bool delete;
}

Future<_MemoEdit?> _showMemoDialog(
  BuildContext context, {
  String initial = '',
  String? quote,
  bool canDelete = false,
}) => showDialog<_MemoEdit>(
  context: context,
  builder:
      (_) => _MemoDialog(initial: initial, quote: quote, canDelete: canDelete),
);

/// Owns its text controller so it is disposed with the dialog, after the
/// closing animation, instead of while the field is still on screen.
class _MemoDialog extends StatefulWidget {
  const _MemoDialog({
    required this.initial,
    required this.quote,
    required this.canDelete,
  });

  final String initial;
  final String? quote;
  final bool canDelete;

  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    return AlertDialog(
      title: Text(widget.canDelete ? '내 메모 편집' : '내 필기 추가'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (quote != null && quote.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '“$quote”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '이 내용에 대한 생각이나 기억할 점을 적어보세요.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.canDelete)
          TextButton(
            onPressed: () => Navigator.pop(context, const _MemoEdit.delete()),
            style: TextButton.styleFrom(foregroundColor: AppColors.coralDark),
            child: const Text('삭제'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(context, _MemoEdit.save(_controller.text)),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

void _showAnnotationSummary(
  BuildContext context,
  List<StudyAnnotation> annotations,
) {
  final highlights =
      annotations
          .where((annotation) => annotation.type == AnnotationType.highlight)
          .length;
  final memos =
      annotations
          .where((annotation) => annotation.type == AnnotationType.memo)
          .length;
  final drawings =
      annotations
          .where(
            (annotation) =>
                annotation.type == AnnotationType.drawing ||
                annotation.type == AnnotationType.freehandHighlight,
          )
          .length;
  final texts =
      annotations
          .where((annotation) => annotation.type == AnnotationType.text)
          .length;
  final bookmarks =
      annotations
          .where((annotation) => annotation.type == AnnotationType.bookmark)
          .length;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '내 학습 기록',
                  style: TextStyle(
                    color: AppColors.homeInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '문단 강조 $highlights개 · 메모 $memos개 · '
                  '자유 필기 $drawings개 · 텍스트 $texts개 · 북마크 $bookmarks개',
                ),
              ],
            ),
          ),
        ),
  );
}

class _ReaderLoading extends StatelessWidget {
  const _ReaderLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.coral));
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('노트를 불러오지 못했어요.'),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

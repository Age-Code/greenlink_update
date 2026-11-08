import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/quick_check.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_editor_controller.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_adaptive_sheet.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/core/widgets/dashed_border.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_writer.dart';

class TutorNoteEditorScreen extends ConsumerStatefulWidget {
  const TutorNoteEditorScreen({super.key, required this.classId, this.noteId});

  final String classId;
  final String? noteId;

  @override
  ConsumerState<TutorNoteEditorScreen> createState() =>
      _TutorNoteEditorScreenState();
}

class _TutorNoteEditorScreenState extends ConsumerState<TutorNoteEditorScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _weekController = TextEditingController(text: '1');
  var _syncedLoadedNote = false;
  String? _autofocusBlockId;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final args = (
      classId: widget.classId,
      userId: user.uid,
      noteId: widget.noteId,
    );
    final provider = noteEditorControllerProvider(args);
    final editor = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final studyClass =
        ref.watch(studyClassProvider(widget.classId)).asData?.value;
    final compact = context.screenType == ScreenType.mobile;

    if (!editor.isLoading && widget.noteId != null && !_syncedLoadedNote) {
      _syncedLoadedNote = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _titleController.text = editor.title;
        _summaryController.text = editor.summary;
        _weekController.text = editor.week.toString();
        setState(() {});
      });
    }

    final busy = editor.isSaving || editor.isLoading;
    final published = editor.status == NoteStatus.published;
    final saveButton = OutlinedButton(
      onPressed: busy ? null : () => _save(context, controller),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.homeInk,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, AppLayout.minTouchHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(published ? '저장' : '초안 저장'),
    );
    final publishButton = FilledButton.icon(
      onPressed:
          busy
              ? null
              : () =>
                  published
                      ? _unpublish(context, controller)
                      : _publish(context, controller, editor),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, AppLayout.minTouchHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      icon: Icon(
        published ? Icons.visibility_off_outlined : Icons.publish_outlined,
        size: 16,
      ),
      label: Text(published ? '게시 취소' : '게시하기'),
    );
    // Figma 15: actions live in a bar pinned under the document.
    final bottomBar =
        compact
            ? Row(
              children: [
                Expanded(child: saveButton),
                const SizedBox(width: 12),
                Expanded(child: publishButton),
              ],
            )
            : Row(
              children: [
                Expanded(child: _SaveStatus(state: editor)),
                saveButton,
                const SizedBox(width: 12),
                publishButton,
              ],
            );

    return AppResponsiveScaffold(
      leading: IconButton(
        tooltip: '나가기',
        onPressed: () => _closeEditor(context, editor),
        icon: const Icon(Icons.close),
      ),
      actions: [
        if (compact)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _SaveStatus(state: editor)),
          ),
      ],
      body:
          editor.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.coral),
              )
              : AppPageBody(
                bottom: 40,
                children: [
                  _DocumentFrame(
                    compact: compact,
                    children: [
                      _MetadataEditor(
                        classTitle: studyClass?.title ?? 'Tugether',
                        titleController: _titleController,
                        summaryController: _summaryController,
                        weekController: _weekController,
                        onTitle: controller.setTitle,
                        onSummary: controller.setSummary,
                        onWeek: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null) controller.setWeek(parsed);
                        },
                      ),
                      if (editor.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          editor.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.coralDark,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      if (editor.blocks.isEmpty)
                        const _EmptyDocument()
                      else
                        for (
                          var index = 0;
                          index < editor.blocks.length;
                          index++
                        ) ...[
                          _BlockEditor(
                            key: ValueKey(editor.blocks[index].id),
                            block: editor.blocks[index],
                            quickCheck:
                                editor.quickChecksByBlockId[editor
                                    .blocks[index]
                                    .id],
                            isFirst: index == 0,
                            isLast: index == editor.blocks.length - 1,
                            autofocus:
                                _autofocusBlockId == editor.blocks[index].id,
                            onContentChanged:
                                (value) => controller.updateBlockContent(
                                  editor.blocks[index].id,
                                  value,
                                ),
                            onLanguageChanged:
                                (value) => controller.updateCodeLanguage(
                                  editor.blocks[index].id,
                                  value,
                                ),
                            onTypeChanged:
                                (value) => controller.updateBlockType(
                                  editor.blocks[index].id,
                                  value,
                                ),
                            onSplitBlock: (type, leading, trailing) {
                              final newBlockId = controller.splitBlock(
                                blockId: editor.blocks[index].id,
                                leadingContent: leading,
                                trailingContent: trailing,
                                newType: type,
                              );
                              setState(() => _autofocusBlockId = newBlockId);
                            },
                            onSlashCommand: () => _showBlockTypeSheet(context),
                            onMoveUp:
                                () => controller.moveBlock(
                                  editor.blocks[index].id,
                                  -1,
                                ),
                            onMoveDown:
                                () => controller.moveBlock(
                                  editor.blocks[index].id,
                                  1,
                                ),
                            onDelete:
                                () => controller.removeBlock(
                                  editor.blocks[index].id,
                                ),
                            onEditQuiz:
                                editor.blocks[index].type == NoteBlockType.quiz
                                    ? () => _configureQuizBlock(
                                      context,
                                      controller,
                                      editor.blocks[index].id,
                                      removeOnCancel: false,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                      _AddBlockButton(
                        onPressed:
                            () => _showAddBlockSheet(context, controller),
                      ),
                    ],
                  ),
                ],
              ),
      bottomBar: editor.isLoading ? null : bottomBar,
    );
  }

  Future<void> _save(
    BuildContext context,
    NoteEditorController controller,
  ) async {
    final noteId = await controller.save();
    if (!context.mounted || noteId == null) return;
    if (widget.noteId == null) {
      context.go(AppRoutes.editTutorNote(widget.classId, noteId));
    }
  }

  Future<void> _publish(
    BuildContext context,
    NoteEditorController controller,
    NoteEditorState editor,
  ) async {
    final validation = editor.validationError(forPublish: true);
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이 노트를 게시할까요?'),
            content: const Text('게시하면 클래스에 참여한 튜티가 노트를 확인할 수 있어요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('게시하기'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final wasDraft = editor.status != NoteStatus.published;
    final noteId = await controller.save(status: NoteStatus.published);
    if (noteId == null) return;
    if (wasDraft) {
      await ref
          .read(notificationWriterProvider)
          .notePublished(
            classId: widget.classId,
            noteId: noteId,
            noteTitle: editor.title.trim(),
          );
    }
    if (!context.mounted) return;
    if (widget.noteId == null) {
      context.go(AppRoutes.editTutorNote(widget.classId, noteId));
    }
  }

  Future<void> _unpublish(
    BuildContext context,
    NoteEditorController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('게시를 취소할까요?'),
            content: const Text('튜티의 노트 목록에서 더 이상 보이지 않게 됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('유지'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('게시 취소'),
              ),
            ],
          ),
    );
    if (confirmed == true) await controller.save(status: NoteStatus.draft);
  }

  Future<void> _closeEditor(
    BuildContext context,
    NoteEditorState editor,
  ) async {
    if (!editor.isDirty) {
      _leaveEditor(context);
      return;
    }
    final close = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('저장하지 않고 나갈까요?'),
            content: const Text('마지막 저장 이후의 변경사항이 사라져요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 작성'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
    );
    if (close == true && context.mounted) _leaveEditor(context);
  }

  void _leaveEditor(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.tutorNotes(widget.classId));
  }

  Future<void> _showAddBlockSheet(
    BuildContext context,
    NoteEditorController controller,
  ) async {
    final type = await _showBlockTypeSheet(context);
    if (type == null) return;
    final blockId = controller.addBlock(type);
    if (type == NoteBlockType.quiz && context.mounted) {
      await _configureQuizBlock(
        context,
        controller,
        blockId,
        removeOnCancel: true,
      );
    }
  }

  Future<void> _configureQuizBlock(
    BuildContext context,
    NoteEditorController controller,
    String blockId, {
    required bool removeOnCancel,
  }) async {
    final action = await showDialog<_QuizBlockAction>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('퀴즈 추가'),
            children: [
              SimpleDialogOption(
                onPressed:
                    () =>
                        Navigator.pop(context, _QuizBlockAction.newQuickCheck),
                child: const ListTile(
                  leading: Icon(Icons.add_circle_outline),
                  title: Text('새 Quick Check 만들기'),
                  subtitle: Text('노트에 맞는 한 문제를 작성해요.'),
                ),
              ),
              SimpleDialogOption(
                onPressed:
                    () => Navigator.pop(
                      context,
                      _QuizBlockAction.existingQuestion,
                    ),
                child: const ListTile(
                  leading: Icon(Icons.link),
                  title: Text('기존 퀴즈에서 선택'),
                  subtitle: Text('게시된 퀴즈의 특정 문제를 연결해요.'),
                ),
              ),
            ],
          ),
    );
    if (!context.mounted) return;
    if (action == null) {
      if (removeOnCancel) controller.removeBlock(blockId);
      return;
    }

    final current = controller.current.quickChecksByBlockId[blockId]!;
    if (action == _QuizBlockAction.newQuickCheck) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final isUnsavedQuickCheck =
          removeOnCancel &&
          current.quizId.startsWith('quiz-') &&
          current.questionId.startsWith('question-');
      final initial =
          isUnsavedQuickCheck
              ? current
              : QuickCheck(
                quizId: 'quiz-$stamp',
                questionId: 'question-$stamp',
                classId: widget.classId,
                noteId: controller.current.noteId ?? '',
                title: 'Quick Check',
                prompt: '',
                options: const ['', '', '', ''],
                correctOptionIndex: -1,
                explanation: '',
                createdBy: current.createdBy,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
      final result = await _showQuickCheckDialog(context, initial);
      if (result == null) {
        if (removeOnCancel) controller.removeBlock(blockId);
      } else {
        controller.linkQuickCheck(blockId, result);
      }
      return;
    }

    final selected = await showDialog<QuickCheck>(
      context: context,
      builder:
          (_) => _QuizQuestionPickerDialog(
            classId: widget.classId,
            noteId: controller.current.noteId ?? '',
          ),
    );
    if (selected == null) {
      if (removeOnCancel) controller.removeBlock(blockId);
    } else {
      controller.linkQuickCheck(blockId, selected);
    }
  }
}

enum _QuizBlockAction { newQuickCheck, existingQuestion }

class _MetadataEditor extends StatelessWidget {
  const _MetadataEditor({
    required this.classTitle,
    required this.titleController,
    required this.summaryController,
    required this.weekController,
    required this.onTitle,
    required this.onSummary,
    required this.onWeek,
  });
  final String classTitle;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController weekController;
  final ValueChanged<String> onTitle;
  final ValueChanged<String> onSummary;
  final ValueChanged<String> onWeek;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            '$classTitle ·',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 70,
            child: _ClickToEditText(
              controller: weekController,
              onChanged: onWeek,
              keyboardType: TextInputType.number,
              displayPrefix: 'Week ',
              hintText: 'Week',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _ClickToEditText(
        controller: titleController,
        onChanged: onTitle,
        style: const TextStyle(
          color: AppColors.homeInk,
          fontSize: 34,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
        hintText: '노트 제목',
      ),
      const SizedBox(height: 10),
      _ClickToEditText(
        controller: summaryController,
        onChanged: onSummary,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.6,
        ),
        hintText: '이 노트에서 배울 내용을 간단히 소개해주세요.',
      ),
    ],
  );
}

class _ClickToEditText extends StatefulWidget {
  const _ClickToEditText({
    required this.controller,
    required this.onChanged,
    required this.style,
    required this.hintText,
    this.keyboardType,
    this.displayPrefix = '',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextStyle style;
  final String hintText;
  final TextInputType? keyboardType;
  final String displayPrefix;

  @override
  State<_ClickToEditText> createState() => _ClickToEditTextState();
}

class _ClickToEditTextState extends State<_ClickToEditText> {
  final _focusNode = FocusNode();
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) setState(() => _editing = false);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _edit() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        maxLines: widget.keyboardType == TextInputType.number ? 1 : null,
        style: widget.style,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      );
    }
    final value = widget.controller.text.trim();
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _edit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            value.isEmpty ? widget.hintText : '${widget.displayPrefix}$value',
            style:
                value.isEmpty
                    ? widget.style.copyWith(color: AppColors.textFaint)
                    : widget.style,
          ),
        ),
      ),
    );
  }
}

class _BlockEditor extends StatefulWidget {
  const _BlockEditor({
    super.key,
    required this.block,
    required this.quickCheck,
    required this.isFirst,
    required this.isLast,
    required this.autofocus,
    required this.onContentChanged,
    required this.onLanguageChanged,
    required this.onTypeChanged,
    required this.onSplitBlock,
    required this.onSlashCommand,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onEditQuiz,
  });
  final NoteBlock block;
  final QuickCheck? quickCheck;
  final bool isFirst;
  final bool isLast;
  final bool autofocus;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<NoteBlockType> onTypeChanged;
  final void Function(
    NoteBlockType type,
    String leadingContent,
    String trailingContent,
  )
  onSplitBlock;
  final Future<NoteBlockType?> Function() onSlashCommand;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback? onEditQuiz;

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  var _editing = false;
  var _hovering = false;
  var _openingSlashMenu = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted && !_openingSlashMenu) {
        setState(() => _editing = false);
      }
    });
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _beginEditing();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _BlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.block.content != _controller.text) {
      _controller.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _beginEditing() {
    if (widget.block.type == NoteBlockType.quiz) {
      widget.onEditQuiz?.call();
      return;
    }
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.block.type == NoteBlockType.code) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _onChanged(String value) {
    widget.onContentChanged(value);
    if (widget.block.type == NoteBlockType.code ||
        widget.block.type == NoteBlockType.image) {
      return;
    }
    if (_openingSlashMenu) return;

    final selection = _controller.selection;
    final cursor =
        selection.isValid && selection.baseOffset >= 0
            ? selection.baseOffset
            : value.length;
    if (cursor > value.length) return;
    final beforeCursor = value.substring(0, cursor);

    if (beforeCursor.endsWith('//')) {
      _openSlashMenu(commandStart: cursor - 2, commandEnd: cursor);
      return;
    }
    if (beforeCursor.endsWith('/') &&
        (cursor == 1 || _isSlashBoundary(value[cursor - 2]))) {
      _openSlashMenu(commandStart: cursor - 1, commandEnd: cursor);
    }
  }

  bool _isSlashBoundary(String character) =>
      character == ' ' || character == '\n' || character == '\t';

  Future<void> _openSlashMenu({int? commandStart, int? commandEnd}) async {
    _openingSlashMenu = true;
    final type = await widget.onSlashCommand();
    if (!mounted) return;
    _openingSlashMenu = false;
    if (type != null) {
      if (commandStart != null &&
          commandEnd != null &&
          commandStart >= 0 &&
          commandEnd <= _controller.text.length &&
          commandStart < commandEnd) {
        final text = _controller.text;
        final leading = text.substring(0, commandStart);
        final trailing = text.substring(commandEnd);
        if (leading.trim().isNotEmpty) {
          _controller.value = TextEditingValue(
            text: leading,
            selection: TextSelection.collapsed(offset: leading.length),
          );
          widget.onSplitBlock(type, leading, trailing);
          return;
        }
        _controller.value = TextEditingValue(
          text: trailing,
          selection: const TextSelection.collapsed(offset: 0),
        );
        widget.onContentChanged(trailing);
      }
      widget.onTypeChanged(type);
      setState(() => _editing = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.block.type != NoteBlockType.code) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovering = true),
    onExit: (_) => setState(() => _hovering = false),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _beginEditing,
          child:
              _editing
                  ? _buildEditor()
                  : _BlockPreview(
                    block: widget.block,
                    quickCheck: widget.quickCheck,
                    onEditQuiz: widget.onEditQuiz,
                  ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: SizedBox(
            width: 36,
            child: IgnorePointer(
              ignoring: !_hovering && !_editing,
              child: AnimatedOpacity(
                opacity: _hovering || _editing ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: PopupMenuButton<String>(
                  tooltip: '블록 메뉴',
                  icon: const Icon(Icons.drag_indicator, size: 19),
                  onSelected: (value) {
                    if (value == 'up') widget.onMoveUp();
                    if (value == 'down') widget.onMoveDown();
                    if (value == 'delete') widget.onDelete();
                    if (value == 'type') _openSlashMenu();
                  },
                  itemBuilder:
                      (_) => [
                        const PopupMenuItem(
                          value: 'type',
                          child: Text('형식 바꾸기'),
                        ),
                        PopupMenuItem(
                          value: 'up',
                          enabled: !widget.isFirst,
                          child: const Text('위로 이동'),
                        ),
                        PopupMenuItem(
                          value: 'down',
                          enabled: !widget.isLast,
                          child: const Text('아래로 이동'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            '삭제',
                            style: TextStyle(color: AppColors.coralDark),
                          ),
                        ),
                      ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEditor() {
    if (widget.block.type == NoteBlockType.code) {
      return Focus(
        autofocus: true,
        onFocusChange: (hasFocus) {
          if (!hasFocus && mounted) setState(() => _editing = false);
        },
        child: _CodeEditor(
          block: widget.block,
          onContentChanged: _onChanged,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      );
    }
    if (widget.block.type == NoteBlockType.quiz) {
      return _QuizEditorCard(
        quickCheck: widget.quickCheck!,
        onEdit: widget.onEditQuiz!,
      );
    }
    final callout = widget.block.type == NoteBlockType.callout;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      maxLines: null,
      minLines: widget.block.type == NoteBlockType.paragraph ? 1 : null,
      style: _blockTextStyle(widget.block.type),
      decoration: InputDecoration(
        hintText: "내용을 입력하거나 '/'로 형식을 선택하세요.",
        hintStyle: const TextStyle(color: AppColors.textFaint),
        filled: callout,
        fillColor: callout ? AppColors.noteMemo : Colors.transparent,
        border:
            callout
                ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.homeDivider),
                )
                : InputBorder.none,
        contentPadding: callout ? const EdgeInsets.all(16) : EdgeInsets.zero,
      ),
    );
  }
}

class _BlockPreview extends StatelessWidget {
  const _BlockPreview({
    required this.block,
    required this.quickCheck,
    required this.onEditQuiz,
  });

  final NoteBlock block;
  final QuickCheck? quickCheck;
  final VoidCallback? onEditQuiz;

  @override
  Widget build(BuildContext context) {
    if (block.content.isEmpty && block.type != NoteBlockType.quiz) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "빈 블록 · 클릭하거나 '/'를 입력하세요.",
          style: TextStyle(color: AppColors.textFaint),
        ),
      );
    }
    if (block.type == NoteBlockType.heading ||
        block.type == NoteBlockType.heading2 ||
        block.type == NoteBlockType.heading3) {
      return Text(block.content, style: _blockTextStyle(block.type));
    }
    return switch (block.type) {
      NoteBlockType.paragraph => Text(
        block.content,
        style: _blockTextStyle(block.type),
      ),
      NoteBlockType.code => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.noteCode,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.language ?? 'code',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Text(block.content, style: _blockTextStyle(block.type)),
          ],
        ),
      ),
      NoteBlockType.quote => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.coral, width: 3)),
        ),
        child: Text(block.content, style: _blockTextStyle(block.type)),
      ),
      NoteBlockType.callout => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.noteMemo,
          border: Border.all(color: AppColors.homeDivider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(block.content, style: _blockTextStyle(block.type)),
      ),
      NoteBlockType.image => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(Icons.image_outlined, color: AppColors.textFaint),
            const SizedBox(height: 8),
            Text(block.content, textAlign: TextAlign.center),
          ],
        ),
      ),
      NoteBlockType.quiz =>
        quickCheck == null
            ? const Text('Quick Check를 불러오지 못했어요.')
            : _QuizEditorCard(
              quickCheck: quickCheck!,
              onEdit: onEditQuiz ?? () {},
            ),
      NoteBlockType.heading => const SizedBox.shrink(),
      NoteBlockType.heading2 => const SizedBox.shrink(),
      NoteBlockType.heading3 => const SizedBox.shrink(),
    };
  }
}

TextStyle _blockTextStyle(NoteBlockType type) => switch (type) {
  NoteBlockType.heading => const TextStyle(
    color: AppColors.homeInk,
    fontSize: 26,
    height: 1.35,
    fontWeight: FontWeight.w800,
  ),
  NoteBlockType.heading2 => const TextStyle(
    color: AppColors.homeInk,
    fontSize: 22,
    height: 1.4,
    fontWeight: FontWeight.w800,
  ),
  NoteBlockType.heading3 => const TextStyle(
    color: AppColors.homeInk,
    fontSize: 18,
    height: 1.45,
    fontWeight: FontWeight.w700,
  ),
  NoteBlockType.code => const TextStyle(
    color: Colors.white,
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.6,
  ),
  NoteBlockType.quote => const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    height: 1.7,
    fontStyle: FontStyle.italic,
  ),
  _ => const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.8),
};

class _CodeEditor extends StatelessWidget {
  const _CodeEditor({
    required this.block,
    required this.onContentChanged,
    required this.onLanguageChanged,
  });
  final NoteBlock block;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.noteCode,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 130,
          child: TextFormField(
            key: ValueKey('${block.id}-language'),
            initialValue: block.language,
            onChanged: onLanguageChanged,
            cursorColor: Colors.white70,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'language',
              hintStyle: TextStyle(color: Colors.white54),
              filled: false,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        TextFormField(
          key: ValueKey(block.id),
          initialValue: block.content,
          autofocus: true,
          onChanged: onContentChanged,
          minLines: 4,
          maxLines: null,
          cursorColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.6,
          ),
          decoration: const InputDecoration(
            hintText: '코드를 입력하세요.',
            hintStyle: TextStyle(color: Colors.white54),
            filled: false,
            border: InputBorder.none,
          ),
        ),
      ],
    ),
  );
}

class _QuizEditorCard extends StatelessWidget {
  const _QuizEditorCard({required this.quickCheck, required this.onEdit});
  final QuickCheck quickCheck;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.noteMemo,
      border: Border.all(color: AppColors.homeDivider),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.bolt, color: AppColors.coralDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUICK CHECK',
                style: TextStyle(
                  color: AppColors.coralDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                quickCheck.prompt.isEmpty ? '문제를 작성해주세요.' : quickCheck.prompt,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '객관식 · ${quickCheck.options.where((item) => item.isNotEmpty).length}개 선택지',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('편집')),
      ],
    ),
  );
}

/// White document card on tablet and desktop (Figma 15); on mobile the
/// blocks sit directly on the page.
class _DocumentFrame extends StatelessWidget {
  const _DocumentFrame({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (compact) return column;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.homeDivider),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08211B19),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: column,
    );
  }
}

class _EmptyDocument extends StatelessWidget {
  const _EmptyDocument();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 30),
    child: Text(
      '아래 버튼으로 첫 학습 블록을 추가해보세요.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

/// Dashed full-width "새로운 학습 블록 추가하기" button (Figma 15).
class _AddBlockButton extends StatelessWidget {
  const _AddBlockButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const DashedBorderPainter(color: AppColors.border, radius: 12),
    child: Material(
      color: Colors.white.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "새로운 학습 블록 추가하기 ('/' 를 입력하거나 클릭)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Block picker (Figma 16): full-width sheet on mobile, inset on tablet,
/// dialog on desktop, with the block types as two columns of tiles.
Future<NoteBlockType?> _showBlockTypeSheet(BuildContext context) {
  return showAppSheet<NoteBlockType>(
    context: context,
    builder: (context) => const _BlockTypeSheet(),
  );
}

class _BlockTypeSheet extends StatelessWidget {
  const _BlockTypeSheet();

  static const _choices = <(NoteBlockType, IconData, String, String)>[
    (NoteBlockType.paragraph, Icons.notes, '텍스트', '기본 설명을 작성합니다.'),
    (NoteBlockType.heading, Icons.looks_one_outlined, '제목 1', '큰 주제를 나눕니다.'),
    (
      NoteBlockType.heading2,
      Icons.looks_two_outlined,
      '제목 2',
      '새로운 학습 주제를 구분합니다.',
    ),
    (NoteBlockType.heading3, Icons.looks_3_outlined, '제목 3', '세부 항목을 묶습니다.'),
    (NoteBlockType.code, Icons.code, '코드', '코드 예제를 추가합니다.'),
    (NoteBlockType.quote, Icons.format_quote, '인용', '핵심 문장을 인용합니다.'),
    (NoteBlockType.callout, Icons.lightbulb_outline, '강조', '중요한 내용을 강조합니다.'),
    (NoteBlockType.image, Icons.image_outlined, '이미지 설명', '학습 이미지를 설명합니다.'),
    (
      NoteBlockType.quiz,
      Icons.quiz_outlined,
      'Quick Check',
      '간단한 확인 문제를 추가합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '블록 추가',
                style: TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '에디터 툴',
                  style: TextStyle(
                    color: AppColors.coralDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "작성 중 '/' 또는 '//'를 입력해도 이 메뉴가 열려요.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (type, icon, label, description) in _choices)
                    SizedBox(
                      width: width,
                      child: _BlockTile(
                        icon: icon,
                        label: label,
                        description: description,
                        recommended: type == NoteBlockType.quiz,
                        onTap: () => Navigator.pop(context, type),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.recommended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: recommended ? AppColors.coralSoft : Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color:
            recommended
                ? AppColors.coral.withValues(alpha: .4)
                : AppColors.border,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: recommended ? Colors.white : AppColors.homeCream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.coralDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          recommended ? AppColors.coralDark : AppColors.homeInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.state});
  final NoteEditorState state;

  @override
  Widget build(BuildContext context) {
    final text =
        state.isSaving
            ? '저장 중...'
            : state.isDirty
            ? '저장 안 됨'
            : state.lastSavedAt != null
            ? '저장됨'
            : '';
    if (text.isEmpty) return const SizedBox.shrink();
    final saved = !state.isSaving && !state.isDirty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          saved ? Icons.check_circle : Icons.schedule,
          size: 14,
          color: saved ? AppColors.sageDark : AppColors.textFaint,
        ),
        const SizedBox(width: 6),
        Text(
          saved ? '변경사항이 저장되었습니다.' : text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _QuizQuestionPickerDialog extends ConsumerStatefulWidget {
  const _QuizQuestionPickerDialog({
    required this.classId,
    required this.noteId,
  });

  final String classId;
  final String noteId;

  @override
  ConsumerState<_QuizQuestionPickerDialog> createState() =>
      _QuizQuestionPickerDialogState();
}

class _QuizQuestionPickerDialogState
    extends ConsumerState<_QuizQuestionPickerDialog> {
  StudyQuiz? _selectedQuiz;

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(allQuizzesProvider(widget.classId));
    final questions =
        _selectedQuiz == null
            ? null
            : ref.watch(
              quizQuestionsProvider((
                classId: widget.classId,
                quizId: _selectedQuiz!.id,
              )),
            );
    return AlertDialog(
      title: Text(_selectedQuiz == null ? '퀴즈 선택' : '문제 선택'),
      content: SizedBox(
        width: 560,
        height: 420,
        child:
            _selectedQuiz == null
                ? quizzes.when(
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      ),
                  error: (_, _) => const Center(child: Text('퀴즈를 불러오지 못했어요.')),
                  data: (items) {
                    final published = items
                        .where((quiz) => quiz.status == QuizStatus.published)
                        .toList(growable: false);
                    if (published.isEmpty) {
                      return const Center(
                        child: Text('게시된 퀴즈가 없어요.\n먼저 퀴즈를 게시해주세요.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: published.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final quiz = published[index];
                        return ListTile(
                          title: Text(quiz.title),
                          subtitle: Text('${quiz.questionCount}문제'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => setState(() => _selectedQuiz = quiz),
                        );
                      },
                    );
                  },
                )
                : questions!.when(
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      ),
                  error: (_, _) => const Center(child: Text('문제를 불러오지 못했어요.')),
                  data:
                      (items) => ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final question = items[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.coralSoft,
                              foregroundColor: AppColors.coralDark,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(question.prompt),
                            subtitle: Text(_selectedQuiz!.title),
                            onTap:
                                () => Navigator.pop(
                                  context,
                                  _asQuickCheck(_selectedQuiz!, question),
                                ),
                          );
                        },
                      ),
                ),
      ),
      actions: [
        if (_selectedQuiz != null)
          TextButton(
            onPressed: () => setState(() => _selectedQuiz = null),
            child: const Text('퀴즈 다시 선택'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  QuickCheck _asQuickCheck(StudyQuiz quiz, QuizQuestion question) => QuickCheck(
    quizId: quiz.id,
    questionId: question.id,
    classId: widget.classId,
    noteId: widget.noteId,
    title: quiz.title,
    prompt: question.prompt,
    options: question.options,
    correctOptionIndex: question.correctOptionIndex,
    explanation: question.explanation,
    createdBy: quiz.createdBy,
    createdAt: quiz.createdAt,
    updatedAt: quiz.updatedAt,
  );
}

Future<QuickCheck?> _showQuickCheckDialog(
  BuildContext context,
  QuickCheck initial,
) async {
  final prompt = TextEditingController(text: initial.prompt);
  final options = [
    for (var index = 0; index < 4; index++)
      TextEditingController(
        text: index < initial.options.length ? initial.options[index] : '',
      ),
  ];
  final explanation = TextEditingController(text: initial.explanation);
  var correctIndex = initial.correctOptionIndex;
  String? error;
  final result = await showDialog<QuickCheck>(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Quick Check 작성'),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: prompt,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '문제',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (var index = 0; index < options.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: correctIndex,
                                  onChanged:
                                      (value) =>
                                          setState(() => correctIndex = value!),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: options[index],
                                    decoration: InputDecoration(
                                      labelText: '선택지 ${index + 1}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: explanation,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '해설',
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            error!,
                            style: const TextStyle(color: AppColors.coralDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final candidate = initial.copyWith(
                        prompt: prompt.text.trim(),
                        options:
                            options.map((item) => item.text.trim()).toList(),
                        correctOptionIndex: correctIndex,
                        explanation: explanation.text.trim(),
                      );
                      if (!candidate.isValid) {
                        setState(
                          () => error = '문제, 4개 선택지, 정답, 해설을 모두 입력해주세요.',
                        );
                        return;
                      }
                      Navigator.pop(context, candidate);
                    },
                    child: const Text('적용'),
                  ),
                ],
              ),
        ),
  );
  prompt.dispose();
  for (final controller in options) {
    controller.dispose();
  }
  explanation.dispose();
  return result;
}

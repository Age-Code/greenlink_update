import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';

class TutorNotesScreen extends ConsumerWidget {
  const TutorNotesScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyClass = ref.watch(studyClassProvider(classId)).asData?.value;
    final notes = ref.watch(allNotesProvider(classId));
    final action = ref.watch(noteActionControllerProvider);
    ref.listen(noteActionControllerProvider, (_, next) {
      next.whenOrNull(
        error: (_, _) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('노트 작업을 완료하지 못했어요.')),
        ),
      );
    });
    return AppResponsiveScaffold(
      menu:
          studyClass == null
              ? null
              : TutorClassMenu(
                studyClass: studyClass,
                selected: ClassMenuItem.notes,
              ),
      body: notes.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.coral),
        ),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(allNotesProvider(classId)),
            child: const Text('다시 불러오기'),
          ),
        ),
        data: (items) => _NotesBody(
          classId: classId,
          notes: items,
          actionDisabled: action.isLoading,
          onCreate: () => context.push(AppRoutes.newTutorNote(classId)),
          onStatus: (note, status) => _changeStatus(context, ref, note, status),
          onDelete: (note) => _delete(context, ref, note),
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    StudyNote note,
    NoteStatus status,
  ) async {
    if (status == NoteStatus.published) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
    }
    if (status == NoteStatus.published) {
      final error = await ref
          .read(noteActionControllerProvider.notifier)
          .publishNote(classId: classId, noteId: note.id);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else {
      await ref.read(noteActionControllerProvider.notifier).setStatus(
            classId: classId,
            noteId: note.id,
            status: status,
          );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    StudyNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트를 삭제할까요?'),
        content: Text('${note.title} 노트와 본문 블록이 삭제됩니다. 개인 메모는 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coralDark),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(noteActionControllerProvider.notifier).deleteNote(
          classId: classId,
          noteId: note.id,
        );
  }
}

class _NotesBody extends StatelessWidget {
  const _NotesBody({
    required this.classId,
    required this.notes,
    required this.actionDisabled,
    required this.onCreate,
    required this.onStatus,
    required this.onDelete,
  });
  final String classId;
  final List<StudyNote> notes;
  final bool actionDisabled;
  final VoidCallback onCreate;
  final void Function(StudyNote, NoteStatus) onStatus;
  final ValueChanged<StudyNote> onDelete;

  @override
  Widget build(BuildContext context) => AppPageBody(
    children: [
      AppPageHeading(
        title: '노트',
        subtitle: '학습 내용을 작성하고 튜티에게 공유해보세요.',
        action: AppHeadingButton(
          label: '새 노트',
          onPressed: actionDisabled ? null : onCreate,
        ),
      ),
      const SizedBox(height: 26),
      if (notes.isEmpty)
        const _EmptyNotes()
      else
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < notes.length; index++) ...[
                _TutorNoteRow(
                  note: notes[index],
                  disabled: actionDisabled,
                  onEdit: () => context.push(
                    AppRoutes.editTutorNote(classId, notes[index].id),
                  ),
                  onStatus: (status) => onStatus(notes[index], status),
                  onDelete: () => onDelete(notes[index]),
                ),
                if (index != notes.length - 1)
                  const Divider(height: 1, color: AppColors.homeDivider),
              ],
            ],
          ),
        ),
    ],
  );
}

class _TutorNoteRow extends StatelessWidget {
  const _TutorNoteRow({
    required this.note,
    required this.disabled,
    required this.onEdit,
    required this.onStatus,
    required this.onDelete,
  });
  final StudyNote note;
  final bool disabled;
  final VoidCallback onEdit;
  final ValueChanged<NoteStatus> onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.coralSoft,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(note.weekLabel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (note.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${note.status == NoteStatus.published ? '게시됨' : '작성 중'} · ${_relativeTime(note.updatedAt)}',
                  style: TextStyle(
                    color: note.status == NoteStatus.published
                        ? AppColors.sageDark
                        : AppColors.coralDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          enabled: !disabled,
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'publish') onStatus(NoteStatus.published);
            if (value == 'unpublish') onStatus(NoteStatus.draft);
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            if (note.status == NoteStatus.draft)
              const PopupMenuItem(value: 'publish', child: Text('게시'))
            else
              const PopupMenuItem(value: 'unpublish', child: Text('게시 취소')),
            const PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
        ),
      ],
    ),
  );
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        Icon(Icons.edit_note, size: 38, color: AppColors.textFaint),
        SizedBox(height: 14),
        Text('아직 작성한 노트가 없어요.'),
      ],
    ),
  );
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return '방금 수정';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전';
  if (difference.inDays < 1) return '${difference.inHours}시간 전';
  return '${difference.inDays}일 전';
}

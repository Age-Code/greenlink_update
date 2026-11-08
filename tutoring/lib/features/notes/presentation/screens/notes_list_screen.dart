import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studyClass = ref.watch(studyClassProvider(widget.classId));
    final notes = ref.watch(publishedNotesProvider(widget.classId));
    final loadedClass = studyClass.asData?.value;
    return AppResponsiveScaffold(
      menu:
          loadedClass == null
              ? null
              : StudentClassMenu(
                studyClass: loadedClass,
                selected: ClassMenuItem.notes,
              ),
      body: notes.when(
        loading: () => const _NotesLoading(),
        error: (_, _) => _NotesError(
          onRetry: () => ref.invalidate(publishedNotesProvider(widget.classId)),
        ),
        data: (items) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? items
              : items
                  .where(
                    (note) => note.title.toLowerCase().contains(query) ||
                        note.summary.toLowerCase().contains(query),
                  )
                  .toList(growable: false);
          return AppPageBody(
            children: [
              const AppPageHeading(
                title: '노트',
                subtitle: '튜터가 공유한 학습 내용을 확인해보세요.',
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '노트 제목이나 내용을 검색해보세요.',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '검색 지우기',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (items.isEmpty)
                _NotesEmptyState(
                  classId: widget.classId,
                  showSeedAction: kDebugMode,
                )
              else ...[
                _ContinueCard(
                  note: items.first,
                  onPressed: () => context.push(
                    AppRoutes.noteReader(
                      widget.classId,
                      items.first.id,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    const Text(
                      '전체 노트',
                      style: TextStyle(
                        color: AppColors.homeInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${filtered.length}개',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      '검색 결과가 없어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  _NotesCard(
                    notes: filtered,
                    onOpen: (noteId) => context.push(
                      AppRoutes.noteReader(widget.classId, noteId),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.note, required this.onPressed});

  final StudyNote note;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final compact = context.screenType == ScreenType.mobile;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
                  'Week ${note.week.toString().padLeft(2, '0')} · 최근 학습',
                  style: const TextStyle(
                    color: AppColors.coralDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  note.title,
                  style: const TextStyle(
                    color: AppColors.homeInk,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: const Text('이어서 보기'),
          icon: const Icon(Icons.arrow_forward, size: 17),
        );
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D211B19),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          foregroundDecoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.coral, width: 4)),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [details, const SizedBox(height: 18), button],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 18),
                    button,
                  ],
                ),
        );
      },
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.onOpen});

  final List<StudyNote> notes;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < notes.length; index++) ...[
            _NoteListTile(note: notes[index], onTap: () => onOpen(notes[index].id)),
            if (index != notes.length - 1)
              const Divider(height: 1, color: AppColors.homeDivider),
          ],
        ],
      ),
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({required this.note, required this.onTap});

  final StudyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: note.week.isEven ? AppColors.sage : AppColors.coralSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                note.weekLabel,
                style: TextStyle(
                  color: note.week.isEven
                      ? AppColors.sageDark
                      : AppColors.coralDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      color: AppColors.homeInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({
    required this.classId,
    required this.showSeedAction,
  });

  final String classId;
  final bool showSeedAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            color: AppColors.textFaint,
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 등록된 노트가 없어요.',
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '튜터가 새로운 학습 노트를 공유하면\n여기에서 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
          if (showSeedAction) ...[
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: () => _showSeedNotice(context),
              icon: const Icon(Icons.science_outlined),
              label: const Text('개발용 샘플 데이터 안내'),
            ),
          ],
        ],
      ),
    );
  }

  void _showSeedNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개발용 샘플 노트'),
        content: SelectableText(
          '프로젝트의 tool/seed_notes.md 안내에 따라 클래스 ID $classId에 샘플 노트를 추가할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _NotesLoading extends StatelessWidget {
  const _NotesLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.onRetry});

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

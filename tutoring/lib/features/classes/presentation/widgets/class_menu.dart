import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_menu_tile.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/student_progress.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_info_sheet.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_filter.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

/// Destinations inside a class. Screens pass the one they show so the menu
/// highlights it.
enum ClassMenuItem { home, notes, quizzes, review }

/// Class menu for students (04_Class_Drawer_Open). Give it to
/// `AppResponsiveScaffold.menu`; it is a drawer on mobile and tablet and a
/// sidebar on desktop. Badges show published notes, quizzes still to solve
/// and review items still pending.
class StudentClassMenu extends ConsumerWidget {
  const StudentClassMenu({
    super.key,
    required this.studyClass,
    required this.selected,
  });

  final StudyClass studyClass;
  final ClassMenuItem selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).asData?.value?.uid;
    final classId = studyClass.id;
    final noteCount =
        ref.watch(publishedNotesProvider(classId)).asData?.value.length;
    final quizzes =
        ref.watch(publishedQuizzesProvider(classId)).asData?.value ??
        const [];
    final List<QuizAttempt> attempts =
        userId == null
            ? const []
            : (ref.watch(quizAttemptsProvider(userId)).asData?.value ??
                    const <QuizAttempt>[])
                .where((attempt) => attempt.classId == classId)
                .toList(growable: false);
    final pendingQuizzes = unsolvedQuizzes(quizzes, attempts).length;
    final pendingReviews =
        userId == null
            ? 0
            : ReviewFilter.needsReview.count(
              ref
                      .watch(
                        classReviewsProvider((
                          userId: userId,
                          classId: classId,
                        )),
                      )
                      .asData
                      ?.value ??
                  const [],
            );

    return _MenuFrame(
      header: _ClassHeader(studyClass: studyClass),
      items: [
        AppMenuTile(
          icon: Icons.home_outlined,
          label: '홈',
          selected: selected == ClassMenuItem.home,
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.home,
                path: AppRoutes.classDetail(classId),
              ),
        ),
        AppMenuTile(
          icon: Icons.menu_book_outlined,
          label: '노트',
          selected: selected == ClassMenuItem.notes,
          trailing: noteCount == null ? null : AppMenuBadge('$noteCount'),
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.notes,
                path: AppRoutes.classNotes(classId),
              ),
        ),
        AppMenuTile(
          icon: Icons.quiz_outlined,
          label: '퀴즈',
          selected: selected == ClassMenuItem.quizzes,
          trailing:
              pendingQuizzes == 0
                  ? null
                  : AppMenuBadge('$pendingQuizzes건 대기', accent: true),
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.quizzes,
                path: AppRoutes.tuteeQuizzes(classId),
              ),
        ),
        AppMenuTile(
          icon: Icons.replay_outlined,
          label: '복습',
          selected: selected == ClassMenuItem.review,
          trailing:
              pendingReviews == 0
                  ? null
                  : AppMenuBadge('$pendingReviews', accent: true),
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.review,
                path: AppRoutes.classReview(classId),
              ),
        ),
      ],
      footer: [
        AppMenuTile(
          icon: Icons.info_outline,
          label: '클래스 정보',
          onTap: () => showClassInfoSheet(context, studyClass),
        ),
        const _BackToClassesButton(),
      ],
    );
  }
}

/// Class menu for the tutor who owns the class: quick "새 노트 작성", home,
/// notes and quizzes with counts, class info and "나가기" (back to my
/// classes). Review has no tutor meaning yet, so it is not listed.
class TutorClassMenu extends ConsumerWidget {
  const TutorClassMenu({
    super.key,
    required this.studyClass,
    required this.selected,
  });

  final StudyClass studyClass;
  final ClassMenuItem selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = studyClass.id;
    final noteCount = ref.watch(allNotesProvider(classId)).asData?.value.length;
    final quizCount =
        ref.watch(allQuizzesProvider(classId)).asData?.value.length;
    return _MenuFrame(
      header: _ClassHeader(studyClass: studyClass),
      cta: _MenuCta(
        icon: Icons.edit_note,
        label: '새 노트 작성',
        onTap: () {
          AppResponsiveScaffold.closeMenu(context);
          context.push(AppRoutes.newTutorNote(classId));
        },
      ),
      items: [
        AppMenuTile(
          icon: Icons.home_outlined,
          label: '홈',
          selected: selected == ClassMenuItem.home,
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.home,
                path: AppRoutes.classDetail(classId),
              ),
        ),
        AppMenuTile(
          icon: Icons.article_outlined,
          label: '노트',
          selected: selected == ClassMenuItem.notes,
          trailing: noteCount == null ? null : AppMenuBadge('$noteCount'),
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.notes,
                path: AppRoutes.tutorNotes(classId),
              ),
        ),
        AppMenuTile(
          icon: Icons.quiz_outlined,
          label: '퀴즈',
          selected: selected == ClassMenuItem.quizzes,
          trailing: quizCount == null ? null : AppMenuBadge('$quizCount'),
          onTap:
              () => _navigate(
                context,
                current: selected,
                target: ClassMenuItem.quizzes,
                path: AppRoutes.tutorQuizzes(classId),
              ),
        ),
      ],
      footer: [
        AppMenuTile(
          icon: Icons.info_outline,
          label: '클래스 정보',
          onTap: () => showClassInfoSheet(context, studyClass),
        ),
        AppMenuTile(
          icon: Icons.logout,
          label: '나가기',
          onTap: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}

/// Soft coral quick-action button under the drawer header (Figma 04).
class _MenuCta extends StatelessWidget {
  const _MenuCta({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.noteMemo,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      hoverColor: AppColors.coralSoft,
      mouseCursor: SystemMouseCursors.click,
      child: SizedBox(
        height: AppLayout.minTouchHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.homeBrown),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.homeBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Book-cover thumbnail, class title, tutor line (Figma 04 drawer header).
class _ClassHeader extends StatelessWidget {
  const _ClassHeader({required this.studyClass});

  final StudyClass studyClass;

  String get _initials {
    final trimmed = studyClass.title.trim();
    if (trimmed.isEmpty) return 'ST';
    final word = trimmed.split(RegExp(r'\s+')).first;
    return word.substring(0, word.length < 2 ? 1 : 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 48,
        height: 56,
        padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
        decoration: BoxDecoration(
          color: AppColors.noteHighlight,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundDecoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.homePeach, width: 3)),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _initials,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: AppColors.homeBrown,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.homeSageDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.menu_book_outlined,
              size: 16,
              color: AppColors.homeBrown,
            ),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studyClass.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.homeInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Tutor · ${studyClass.tutorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '진행 중',
                  style: TextStyle(
                    color: AppColors.homeSageDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

/// Shared frame: header with a close chevron in drawer mode, an optional
/// quick action, the entries, then the footer pinned to the bottom.
class _MenuFrame extends StatelessWidget {
  const _MenuFrame({
    required this.items,
    required this.footer,
    required this.header,
    this.cta,
  });

  final Widget header;

  /// Optional quick action shown under the header.
  final Widget? cta;
  final List<Widget> items;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final isDrawer = AppResponsiveScaffold.isMenuDrawer(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                if (isDrawer)
                  IconButton(
                    tooltip: '메뉴 닫기',
                    onPressed: () => AppResponsiveScaffold.hideMenu(context),
                    icon: const Icon(Icons.chevron_left),
                  ),
              ],
            ),
            if (cta != null) ...[const SizedBox(height: AppSpacing.md), cta!],
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            ...items,
            const Spacer(),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.xs),
            ...footer,
          ],
        ),
      ),
    );
  }
}

class _BackToClassesButton extends StatelessWidget {
  const _BackToClassesButton();

  @override
  Widget build(BuildContext context) => AppMenuTile(
    icon: Icons.arrow_back,
    label: '내 클래스 목록',
    onTap: () => context.go(AppRoutes.home),
  );
}

/// Closes the drawer (if any) and moves to [target].
///
/// From the class home other screens are pushed so their back arrow returns
/// here; between sibling screens the route is replaced so the stack does not
/// grow; the class home itself resets the class stack.
void _navigate(
  BuildContext context, {
  required ClassMenuItem current,
  required ClassMenuItem target,
  required String path,
}) {
  AppResponsiveScaffold.closeMenu(context);
  if (target == current) return;
  if (target == ClassMenuItem.home) {
    context.go(path);
  } else if (current == ClassMenuItem.home) {
    context.push(path);
  } else {
    context.pushReplacement(path);
  }
}

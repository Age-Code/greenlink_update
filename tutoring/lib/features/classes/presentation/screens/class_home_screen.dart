import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/format/relative_time.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/student_progress.dart';
import 'package:tutoring/features/classes/presentation/screens/tutor_class_home_screen.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_info_sheet.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_filter.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';

const _classAssetRoot = 'assets/images/classes';

class ClassHomeScreen extends ConsumerWidget {
  const ClassHomeScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const _LoadingScaffold();
    final profile = ref.watch(userProfileProvider(user.uid));
    final role = profile.asData?.value?.role;
    final studyClass = ref.watch(studyClassProvider(classId));
    final notes = ref.watch(publishedNotesProvider(classId));
    if (profile.isLoading) return const _LoadingScaffold();
    return studyClass.when(
      loading: () => const _LoadingScaffold(),
      error:
          (_, _) => AppResponsiveScaffold(
            leading: IconButton(
              tooltip: '내 클래스 목록',
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.arrow_back),
            ),
            body: Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(studyClassProvider(classId)),
                child: const Text('다시 불러오기'),
              ),
            ),
          ),
      data:
          (value) =>
              value == null
                  ? const Scaffold(
                    backgroundColor: AppColors.background,
                    body: Center(child: Text('클래스를 찾을 수 없어요.')),
                  )
                  : role == UserRole.tutor && user.uid == value.tutorId
                  ? TutorClassHomeScreen(studyClass: value)
                  : _ClassHomeContent(
                    studyClass: value,
                    notes: notes,
                    userId: user.uid,
                  ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
  );
}

/// 03_Class_Home_Student. Numbers come from the learner's own records:
/// finished quizzes, pending review items, latest activity.
class _ClassHomeContent extends ConsumerWidget {
  const _ClassHomeContent({
    required this.studyClass,
    required this.notes,
    required this.userId,
  });

  final StudyClass studyClass;
  final AsyncValue<List<StudyNote>> notes;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = studyClass.id;
    final quizzes =
        ref.watch(publishedQuizzesProvider(classId)).asData?.value ?? const [];
    final attempts =
        (ref.watch(quizAttemptsProvider(userId)).asData?.value ?? const [])
            .where((attempt) => attempt.classId == classId)
            .toList(growable: false);
    final reviews =
        ref
            .watch(classReviewsProvider((userId: userId, classId: classId)))
            .asData
            ?.value ??
        const [];
    final noteItems = notes.asData?.value ?? const <StudyNote>[];
    final latestNote = noteItems.isEmpty ? null : noteItems.first;

    final recentNotes = _RecentNotes(classId: classId, notes: notes);
    final tasks = _ActivityTasks(
      classId: classId,
      hasQuizzes: quizzes.isNotEmpty,
      pendingQuizzes: unsolvedQuizzes(quizzes, attempts).length,
      pendingReviews: ReviewFilter.needsReview.count(reviews),
    );

    return AppResponsiveScaffold(
      menu: StudentClassMenu(
        studyClass: studyClass,
        selected: ClassMenuItem.home,
      ),
      menuIcon: SvgPicture.asset('$_classAssetRoot/menu.svg', width: 18),
      actions: [
        IconButton(
          tooltip: '클래스 정보',
          onPressed: () => showClassInfoSheet(context, studyClass),
          icon: SvgPicture.asset('$_classAssetRoot/more.svg', height: 17),
        ),
      ],
      body: AppPageBody(
        children: [
          _ClassIntro(studyClass: studyClass),
          const SizedBox(height: 36),
          _LearningHero(
            classId: classId,
            note: latestNote,
            hasQuizzes: quizzes.isNotEmpty,
            progress: quizCompletionProgress(quizzes, attempts),
            lastStudied: latestStudyTime(attempts),
          ),
          const SizedBox(height: 36),
          if (context.screenType == ScreenType.mobile)
            Column(
              children: [recentNotes, const SizedBox(height: 24), tasks],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: recentNotes),
                const SizedBox(width: 24),
                Expanded(flex: 5, child: tasks),
              ],
            ),
          const SizedBox(height: 96),
          const Text(
            'Tugether · 조용하고 차분한 학술 서재 환경',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ClassIntro extends StatelessWidget {
  const _ClassIntro({required this.studyClass});

  final StudyClass studyClass;

  @override
  Widget build(BuildContext context) {
    final mobile = context.screenType == ScreenType.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학습 클래스 · Tutor ${studyClass.tutorName}',
          style: const TextStyle(
            color: AppColors.homeMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          studyClass.title,
          style: TextStyle(
            color: AppColors.homeInk,
            fontSize: mobile ? 26 : 30,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.75,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            studyClass.description.isEmpty
                ? '함께 배우고 기록하는 스터디 클래스입니다.'
                : studyClass.description,
            style: const TextStyle(
              color: AppColors.homeMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero card: the latest note with the class progress bar and "이어서 보기".
class _LearningHero extends ConsumerWidget {
  const _LearningHero({
    required this.classId,
    required this.note,
    required this.hasQuizzes,
    required this.progress,
    required this.lastStudied,
  });

  final String classId;
  final StudyNote? note;
  final bool hasQuizzes;
  final double progress;
  final DateTime? lastStudied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = note;
    final blockCount =
        current == null
            ? 0
            : ref
                    .watch(
                      noteBlocksProvider((classId: classId, noteId: current.id)),
                    )
                    .asData
                    ?.value
                    .length ??
                0;
    final mobile = context.screenType == ScreenType.mobile;
    final studied = lastStudied;

    return Container(
      padding: EdgeInsets.all(mobile ? AppSpacing.xl : 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FD9684F),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      foregroundDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.coral, width: 4)),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _WeekBadge(
                label: current == null ? '노트 준비 중' : _weekLabel(current.week),
                bordered: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              SvgPicture.asset('$_classAssetRoot/clock.svg', width: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  studied == null
                      ? '아직 학습 기록이 없어요'
                      : '최근 학습 · ${relativeTimeLabel(studied)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.homeMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!mobile && studied != null) ...[
                const Spacer(),
                const _SagePill(label: '학습 중인 세션'),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            current?.title ?? '아직 게시된 노트가 없어요',
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: mobile ? 26 : 30,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.75,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            current?.summary ?? '튜터가 노트를 올리면 여기에서 이어서 볼 수 있어요.',
            style: TextStyle(
              color: AppColors.homeMuted,
              fontSize: mobile ? 15 : 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      '학습 달성도',
                      style: TextStyle(color: AppColors.homeMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      hasQuizzes
                          ? '진행률 ${(progress * 100).round()}%'
                          : '게시된 퀴즈 없음',
                      style: const TextStyle(
                        color: AppColors.homeBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: AppColors.coral,
                    backgroundColor: AppColors.noteHighlight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              FilledButton(
                onPressed:
                    () => context.push(
                      current == null
                          ? AppRoutes.classNotes(classId)
                          : AppRoutes.noteReader(classId, current.id),
                    ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(0, AppLayout.minTouchHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current == null ? '노트 목록 보기' : '이어서 보기',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.arrow_forward, size: 14),
                  ],
                ),
              ),
              if (current != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '예상 소요 시간 약 ${estimatedReadingMinutes(blockCount)}분',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _weekLabel(int week) => 'Week ${week.toString().padLeft(2, '0')}';

class _RecentNotes extends StatelessWidget {
  const _RecentNotes({required this.classId, required this.notes});

  final String classId;
  final AsyncValue<List<StudyNote>> notes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: AppLayout.minTouchHeight,
        child: Row(
          children: [
          SvgPicture.asset('$_classAssetRoot/notes.svg', width: 18, height: 18),
          const SizedBox(width: AppSpacing.xs),
          const Expanded(child: _SectionTitle('최근 노트')),
          TextButton(
            onPressed: () => context.push(AppRoutes.classNotes(classId)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.homeBrown,
              minimumSize: const Size(0, AppLayout.minTouchHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('전체 보기', style: TextStyle(fontSize: 12)),
                Icon(Icons.chevron_right, size: 14),
              ],
            ),
          ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: notes.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.coral),
                ),
              ),
          error:
              (_, _) => Padding(
                padding: const EdgeInsets.all(28),
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.classNotes(classId)),
                  child: const Text('노트 목록에서 다시 시도'),
                ),
              ),
          data:
              (items) =>
                  items.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              color: AppColors.textFaint,
                              size: 32,
                            ),
                            SizedBox(height: 10),
                            Text(
                              '아직 등록된 학습 노트가 없어요.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          for (final (index, note) in items.take(3).indexed) ...[
                            if (index > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.noteHighlight,
                              ),
                            _NoteRow(
                              note: note,
                              onTap:
                                  () => context.push(
                                    AppRoutes.noteReader(classId, note.id),
                                  ),
                            ),
                          ],
                        ],
                      ),
        ),
      ),
    ],
  );
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onTap});

  final StudyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      hoverColor: AppColors.softGray,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _WeekBadge(label: _weekLabel(note.week), bordered: false),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.homeInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              relativeTimeLabel(note.publishedAt ?? note.updatedAt),
              style: const TextStyle(color: AppColors.homeMuted, fontSize: 11),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textFaint),
          ],
        ),
      ),
    ),
  );
}

class _ActivityTasks extends StatelessWidget {
  const _ActivityTasks({
    required this.classId,
    required this.hasQuizzes,
    required this.pendingQuizzes,
    required this.pendingReviews,
  });

  final String classId;
  final bool hasQuizzes;
  final int pendingQuizzes;
  final int pendingReviews;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Same height as the notes header so both titles sit on one line.
      SizedBox(
        height: AppLayout.minTouchHeight,
        child: Row(
          children: [
            SvgPicture.asset(
              '$_classAssetRoot/tasks.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            const _SectionTitle('활동 과제'),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _TaskCard(
        asset: '$_classAssetRoot/quiz.svg',
        label: '퀴즈',
        accent: AppColors.coralDark,
        chipColor: AppColors.coralSoft,
        chipBorder: AppColors.homePeach,
        dotColor: AppColors.coral,
        linkColor: AppColors.homeBrown,
        text:
            !hasQuizzes
                ? '아직 게시된 퀴즈가 없어요.'
                : pendingQuizzes == 0
                ? '모든 퀴즈를 풀었어요.'
                : '풀지 않은 퀴즈가 $pendingQuizzes개 있어요.',
        linkLabel: '퀴즈 풀기',
        onTap: () => context.push(AppRoutes.tuteeQuizzes(classId)),
      ),
      const SizedBox(height: AppSpacing.md),
      _TaskCard(
        asset: '$_classAssetRoot/review.svg',
        label: '복습',
        accent: AppColors.sageDark,
        chipColor: AppColors.sage,
        chipBorder: AppColors.homeSage,
        dotColor: AppColors.homeSageDark,
        linkColor: AppColors.homeSageDark,
        text:
            pendingReviews == 0
                ? '다시 확인할 문제가 없어요.'
                : '다시 확인할 문제가 $pendingReviews개 있어요.',
        linkLabel: '복습하기',
        onTap: () => context.push(AppRoutes.classReview(classId)),
      ),
    ],
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.asset,
    required this.label,
    required this.accent,
    required this.chipColor,
    required this.chipBorder,
    required this.dotColor,
    required this.linkColor,
    required this.text,
    required this.linkLabel,
    required this.onTap,
  });

  final String asset;
  final String label;
  final Color accent;
  final Color chipColor;
  final Color chipBorder;
  final Color dotColor;
  final Color linkColor;
  final String text;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      hoverColor: AppColors.softGray,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    border: Border.all(color: chipBorder),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(asset, width: 12, height: 12),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.homeInk,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.noteHighlight),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  linkLabel,
                  style: TextStyle(color: linkColor, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, size: 12, color: linkColor),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.homeInk,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _WeekBadge extends StatelessWidget {
  const _WeekBadge({required this.label, required this.bordered});

  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: bordered ? 13 : 10,
      vertical: bordered ? 5 : 4,
    ),
    decoration: BoxDecoration(
      color: AppColors.noteMemo,
      border: bordered ? Border.all(color: AppColors.border) : null,
      borderRadius: BorderRadius.circular(bordered ? 999 : 6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.homeBrown,
        fontSize: bordered ? 12 : 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SagePill extends StatelessWidget {
  const _SagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.sage,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.sageDark,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.sageDark,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/format/relative_time.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/core/widgets/primary_button.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/tutor_dashboard.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_info_sheet.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';
import 'package:tutoring/features/notes/domain/entities/note_status.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';

/// 13_Tutor_Class_Home: workspace intro, the draft to continue, three
/// metrics, recent notes and per-student progress. Pinned "새 노트 작성".
class TutorClassHomeScreen extends ConsumerWidget {
  const TutorClassHomeScreen({super.key, required this.studyClass});

  final StudyClass studyClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = studyClass.id;
    final notes = ref.watch(allNotesProvider(classId));
    return AppResponsiveScaffold(
      menu: TutorClassMenu(studyClass: studyClass, selected: ClassMenuItem.home),
      actions: [
        IconButton(
          tooltip: '클래스 정보',
          onPressed: () => showClassInfoSheet(context, studyClass),
          icon: const Icon(Icons.more_vert),
        ),
      ],
      bottomBar: PrimaryButton(
        label: '새 노트 작성',
        icon: Icons.add,
        iconLeading: true,
        height: 56,
        onPressed: () => context.push(AppRoutes.newTutorNote(classId)),
      ),
      body: notes.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
        error:
            (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(allNotesProvider(classId)),
                child: const Text('다시 불러오기'),
              ),
            ),
        data: (items) => _TutorBody(studyClass: studyClass, notes: items),
      ),
    );
  }
}

class _TutorBody extends ConsumerWidget {
  const _TutorBody({required this.studyClass, required this.notes});

  final StudyClass studyClass;
  final List<StudyNote> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = studyClass.id;
    final quizzes =
        ref.watch(allQuizzesProvider(classId)).asData?.value ??
        const <StudyQuiz>[];
    final publishedQuizzes =
        quizzes
            .where((quiz) => quiz.status == QuizStatus.published)
            .toList(growable: false);
    final publishedNotes =
        notes
            .where((note) => note.status == NoteStatus.published)
            .toList(growable: false);
    final members = ref.watch(classMembersProvider(classId));
    final attempts = ref.watch(classQuizAttemptsProvider(classId));
    final attemptItems = attempts.asData?.value ?? const <QuizAttempt>[];
    final students = buildStudentProgress(
      members: members.asData?.value ?? const [],
      publishedNotes: publishedNotes,
      publishedQuizzes: publishedQuizzes,
      attempts: attemptItems,
    );
    final drafts =
        notes.where((note) => note.status == NoteStatus.draft).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent =
        notes.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final mobile = context.screenType == ScreenType.mobile;

    return AppPageBody(
      top: AppSpacing.md,
      bottom: AppSpacing.xl,
      children: [
        _Intro(studyClass: studyClass),
        const SizedBox(height: AppSpacing.xl),
        _ContinueCard(
          classId: classId,
          draft: drafts.isEmpty ? null : drafts.first,
        ),
        const SizedBox(height: 36),
        _Metrics(
          mobile: mobile,
          cards: [
            _MetricCard(
              label: '정리된 노트',
              icon: Icons.menu_book_outlined,
              value: '노트 ${publishedNotes.length}개',
              caption:
                  recent.isEmpty
                      ? '아직 노트가 없어요'
                      : '최근 업데이트 ${relativeTimeLabel(recent.first.updatedAt)}',
            ),
            _MetricCard(
              label: '과제 및 퀴즈',
              icon: Icons.quiz_outlined,
              value: '퀴즈 ${publishedQuizzes.length}개',
              caption:
                  '평균 제출율 ${(submissionRate(students: students, publishedQuizzes: publishedQuizzes, attempts: attemptItems) * 100).round()}%',
            ),
            _MetricCard(
              label: '학습 공동체',
              icon: Icons.people_outline,
              value: '참여 학생 ${students.length}명',
              caption: _communityCaption(students),
              captionDot: students.isNotEmpty,
            ),
          ],
        ),
        const SizedBox(height: 36),
        _SectionHeader(
          title: '최근 노트',
          linkLabel: '전체 보기',
          onLink: () => context.push(AppRoutes.tutorNotes(classId)),
        ),
        const SizedBox(height: AppSpacing.md),
        _RecentNotes(classId: classId, notes: recent.take(3).toList()),
        const SizedBox(height: 48),
        const _SectionHeader(title: '학습 현황'),
        const SizedBox(height: AppSpacing.md),
        if (members.isLoading || attempts.isLoading)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          )
        else if (attempts.hasError || members.hasError)
          _InlineError(
            message: '학습 현황을 불러오지 못했어요.',
            onRetry: () {
              ref.invalidate(classQuizAttemptsProvider(classId));
              ref.invalidate(classMembersProvider(classId));
            },
          )
        else ...[
          _ProgressSummary(students: students),
          const SizedBox(height: AppSpacing.xs),
          _StudentList(students: students, mobile: mobile),
        ],
      ],
    );
  }

  static String _communityCaption(List<StudentProgress> students) {
    if (students.isEmpty) return '참여 코드를 공유해보세요';
    final active = activeThisWeek(students);
    if (active == students.length) return '모두 활동 중';
    return '$active명 이번 주 활동';
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.studyClass});

  final StudyClass studyClass;

  @override
  Widget build(BuildContext context) {
    final mobile = context.screenType == ScreenType.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '강의 워크스페이스',
              style: TextStyle(
                color: AppColors.homeBrown,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              semesterLabel(studyClass.createdAt),
              style: const TextStyle(
                color: AppColors.homeMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                ? '튜티와 함께 학습할 자료를 준비해보세요.'
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

/// "최근 작업": the newest draft with "이어서 작성", or an invitation to start.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.classId, required this.draft});

  final String classId;
  final StudyNote? draft;

  @override
  Widget build(BuildContext context) {
    final note = draft;
    final mobile = context.screenType == ScreenType.mobile;
    final button = FilledButton(
      onPressed:
          () => context.push(
            note == null
                ? AppRoutes.newTutorNote(classId)
                : AppRoutes.editTutorNote(classId, note.id),
          ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.surface,
        minimumSize: const Size(0, AppLayout.minTouchHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note == null ? '새 노트 작성' : '이어서 작성',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Icon(note == null ? Icons.add : Icons.arrow_forward, size: 14),
        ],
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '최근 작업',
              style: TextStyle(
                color: AppColors.homeMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.55,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _StatusChip(status: note == null ? null : NoteStatus.draft),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          note == null ? '작성 중인 노트가 없어요' : '${_weekLabel(note.week)} ${note.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.homeInk,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          note == null
              ? 'Week별 개념 정리를 새 노트로 시작해보세요.'
              : (note.summary.isEmpty ? '요약이 아직 없어요.' : note.summary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.homeMuted,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 13,
                color: AppColors.homeMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '마지막 수정 · ${relativeTimeLabel(note.updatedAt)}',
                style: const TextStyle(
                  color: AppColors.homeMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface, AppColors.noteMemo],
          stops: [0, 0.5, 1],
        ),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08211B19),
            offset: Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      foregroundDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.coral, width: 4)),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child:
          mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [texts, const SizedBox(height: AppSpacing.md), button],
              )
              : Row(
                children: [
                  Expanded(child: texts),
                  const SizedBox(width: AppSpacing.md),
                  button,
                ],
              ),
    );
  }
}

/// Three metric cards: a row on tablet and desktop, a horizontal scroll on
/// mobile.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.mobile, required this.cards});

  final bool mobile;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (!mobile) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[index]),
            ],
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 200, child: cards[index]),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.caption,
    this.captionDot = false,
  });

  final String label;
  final IconData icon;
  final String value;
  final String caption;
  final bool captionDot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.homeMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(icon, size: 16, color: AppColors.homeBrown),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.homeInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (captionDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.sageDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: captionDot ? AppColors.homeSageDark : AppColors.homeMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.linkLabel, this.onLink});

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppLayout.minTouchHeight,
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.homeInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.45,
            ),
          ),
        ),
        if (linkLabel != null)
          TextButton(
            onPressed: onLink,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.homeMuted,
              minimumSize: const Size(0, AppLayout.minTouchHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(linkLabel!, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.arrow_forward, size: 12),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RecentNotes extends StatelessWidget {
  const _RecentNotes({required this.classId, required this.notes});

  final String classId;
  final List<StudyNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: const Text(
          '아직 노트가 없어요. 아래 버튼으로 첫 노트를 작성해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (final (index, note) in notes.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            _NoteRow(
              note: note,
              onTap: () => context.push(AppRoutes.editTutorNote(classId, note.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onTap});

  final StudyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final published = note.status == NoteStatus.published;
    final time = relativeTimeLabel(note.publishedAt ?? note.updatedAt);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.softGray,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.noteMemo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  published ? Icons.article_outlined : Icons.edit_note,
                  size: 18,
                  color: AppColors.homeBrown,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap so a long title or a narrow phone pushes the
                    // status chip to the next line instead of overflowing.
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _weekLabel(note.week),
                          style: const TextStyle(
                            color: AppColors.homeMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.homeInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _StatusChip(status: note.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.summary.isEmpty ? '요약이 아직 없어요.' : note.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.homeMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                published ? '$time 게시' : time,
                style: const TextStyle(
                  color: AppColors.homeMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// "작성 중" / "게시됨" chip. A null status shows a neutral "시작 전".
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final NoteStatus? status;

  @override
  Widget build(BuildContext context) {
    final published = status == NoteStatus.published;
    final draft = status == NoteStatus.draft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:
            published
                ? AppColors.sage
                : draft
                ? AppColors.coralSoft
                : AppColors.softGray,
        border: Border.all(
          color:
              published
                  ? AppColors.homeSage
                  : draft
                  ? AppColors.homePeach
                  : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        published
            ? '게시됨'
            : draft
            ? '작성 중'
            : '시작 전',
        style: TextStyle(
          color:
              published
                  ? AppColors.sageDark
                  : draft
                  ? AppColors.coralDark
                  : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.students});

  final List<StudentProgress> students;

  @override
  Widget build(BuildContext context) {
    final average = averageProgress(students);
    final active = activeThisWeek(students);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.coralSoft.withValues(alpha: 0.3),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '평균 학습 진행률',
            style: TextStyle(
              color: AppColors.homeMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(average * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  students.isEmpty
                      ? '아직 참여한 학생이 없어요.'
                      : '${students.length}명 중 $active명이 이번 주 학습을 진행하고 있어요.',
                  style: const TextStyle(
                    color: AppColors.homeMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: average,
              minHeight: 8,
              color: AppColors.coral,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students, required this.mobile});

  final List<StudentProgress> students;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: const Text(
          '아직 참여한 학생이 없어요. 참여 코드를 공유해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (final (index, student) in students.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            _StudentRow(student: student, index: index, mobile: mobile),
          ],
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.index,
    required this.mobile,
  });

  final StudentProgress student;
  final int index;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final accent = index.isEven ? AppColors.homeBrown : AppColors.homeSageDark;
    final note = student.currentNote;
    final lastStudied = student.lastStudied;
    final progressBar = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: student.progress,
              minHeight: 6,
              color: index.isEven ? AppColors.coral : AppColors.sageDark,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${student.progressPercent}%',
          style: const TextStyle(
            color: AppColors.homeInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final lastLabel = Text(
      lastStudied == null
          ? '아직 학습 전'
          : '최근 학습 · ${relativeTimeLabel(lastStudied)}',
      style: const TextStyle(
        color: AppColors.homeMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    final identity = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.noteHighlight,
            border: Border.all(color: AppColors.border),
            shape: BoxShape.circle,
          ),
          child: Text(
            student.name.characters.first,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.homeInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      note != null
                          ? '${_weekLabel(note.week)} · ${note.title}'
                          : lastStudied == null
                          ? '아직 학습 전'
                          : '퀴즈 풀이 중',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.homeMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '노트 ${student.notesTouched}/${student.noteTotal} · 퀴즈 ${student.quizzesDone}/${student.quizTotal}',
                style: const TextStyle(color: AppColors.homeMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child:
          mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      progressBar,
                      const Spacer(),
                      lastLabel,
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      progressBar,
                      const SizedBox(height: AppSpacing.xxs),
                      lastLabel,
                    ],
                  ),
                ],
              ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

String _weekLabel(int week) => 'Week ${week.toString().padLeft(2, '0')}';

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  border: Border.all(color: AppColors.border),
  borderRadius: BorderRadius.circular(16),
  boxShadow: const [
    BoxShadow(color: Color(0x08211B19), offset: Offset(0, 2), blurRadius: 12),
  ],
);

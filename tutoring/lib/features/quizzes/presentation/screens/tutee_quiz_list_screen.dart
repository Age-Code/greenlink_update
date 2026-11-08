import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';
import 'package:tutoring/features/classes/presentation/controllers/student_progress.dart';

class TuteeQuizListScreen extends ConsumerWidget {
  const TuteeQuizListScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final studyClass = ref.watch(studyClassProvider(classId)).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final quizzes = ref.watch(publishedQuizzesProvider(classId));
    final attempts = ref.watch(quizAttemptsProvider(user.uid));
    return AppResponsiveScaffold(
      menu:
          studyClass == null
              ? null
              : StudentClassMenu(
                studyClass: studyClass,
                selected: ClassMenuItem.quizzes,
              ),
      body: quizzes.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
        error:
            (_, _) => _LoadError(
              onRetry: () => ref.invalidate(publishedQuizzesProvider(classId)),
            ),
        data:
            (items) => attempts.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: AppColors.coral),
                  ),
              error:
                  (_, _) => _LoadError(
                    onRetry:
                        () => ref.invalidate(quizAttemptsProvider(user.uid)),
                  ),
              data:
                  (history) => _QuizList(
                    classId: classId,
                    quizzes: items,
                    attempts: history
                        .where((attempt) => attempt.classId == classId)
                        .toList(growable: false),
                  ),
            ),
      ),
    );
  }
}

class _QuizList extends StatelessWidget {
  const _QuizList({
    required this.classId,
    required this.quizzes,
    required this.attempts,
  });

  final String classId;
  final List<StudyQuiz> quizzes;
  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) => AppPageBody(
    children: [
      const AppPageHeading(title: '퀴즈', subtitle: '배운 내용을 확인해보세요.'),
      const SizedBox(height: 28),
      if (quizzes.isEmpty)
        const _EmptyState()
      else ...[
        Row(
          children: [
            const Expanded(
              child: Text(
                '전체 퀴즈 목록',
                style: TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              '총 ${quizzes.length}개',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var index = 0; index < quizzes.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, color: AppColors.homeDivider),
                _QuizRow(
                  quiz: quizzes[index],
                  latestAttempt: _latestAttempt(quizzes[index]),
                  attemptCount: _attemptsFor(quizzes[index]).length,
                  onStart:
                      () => context.push(
                        AppRoutes.solveQuiz(classId, quizzes[index].id),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );

  List<QuizAttempt> _attemptsFor(StudyQuiz quiz) =>
      attemptsForQuiz(quiz, attempts);

  QuizAttempt? _latestAttempt(StudyQuiz quiz) {
    final matches = _attemptsFor(quiz).toList(growable: true);
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return matches.first;
  }
}

/// One quiz as a list row (Figma 07): icon, title with a status chip,
/// "n문제 · 상태", and the start / retry button. On mobile the button drops
/// under the text so neither has to wrap.
class _QuizRow extends StatelessWidget {
  const _QuizRow({
    required this.quiz,
    required this.latestAttempt,
    required this.attemptCount,
    required this.onStart,
  });

  final StudyQuiz quiz;
  final QuizAttempt? latestAttempt;
  final int attemptCount;
  final VoidCallback onStart;

  /// "최근 점수 3/4 · 2번 풀었어요" once attempted; the quiz counts as attempted
  /// only after its last question was completed.
  String get _statusLabel {
    final latest = latestAttempt;
    if (latest == null) return '아직 풀지 않았어요';
    return '최근 점수 ${latest.correctCount}/${latest.totalQuestions} · $attemptCount번 풀었어요';
  }

  bool get _isPerfect {
    final latest = latestAttempt;
    return latest != null && latest.correctCount == latest.totalQuestions;
  }

  Color get _statusColor {
    if (latestAttempt == null) return AppColors.textSecondary;
    return _isPerfect ? AppColors.sageDark : AppColors.coralDark;
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.screenType == ScreenType.mobile;
    final attempted = latestAttempt != null;
    final icon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: attempted ? AppColors.homeSage : AppColors.coralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        attempted ? Icons.replay : Icons.data_object,
        size: 18,
        color: attempted ? AppColors.homeSageDark : AppColors.coralDark,
      ),
    );
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: attempted ? AppColors.homeSage : AppColors.coralSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        attempted ? (_isPerfect ? '완료' : '다시 풀기 추천') : '미완료',
        style: TextStyle(
          color: attempted ? AppColors.homeSageDark : AppColors.coralDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              quiz.title,
              style: const TextStyle(
                color: AppColors.homeInk,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            chip,
          ],
        ),
        if (quiz.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            quiz.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${quiz.questionCount}문제',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Text(
              '·',
              style: TextStyle(color: AppColors.textFaint, fontSize: 13),
            ),
            Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(compact ? double.infinity : 0, AppLayout.minTouchHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
    final button =
        attempted
            ? OutlinedButton(
              onPressed: onStart,
              style: buttonStyle.copyWith(
                foregroundColor: const WidgetStatePropertyAll(
                  AppColors.homeInk,
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: AppColors.border),
                ),
              ),
              child: const Text('다시 풀기'),
            )
            : FilledButton(
              onPressed: onStart,
              style: buttonStyle.copyWith(
                backgroundColor: const WidgetStatePropertyAll(AppColors.coral),
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
              ),
              child: const Text('시작하기'),
            );
    return Padding(
      padding: const EdgeInsets.all(20),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 14),
                  button,
                ],
              )
              : Row(
                children: [
                  icon,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  button,
                ],
              ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 80),
    child: Column(
      children: [
        Icon(Icons.quiz_outlined, size: 40, color: AppColors.textFaint),
        SizedBox(height: 12),
        Text(
          '아직 게시된 퀴즈가 없어요.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(onPressed: onRetry, child: const Text('다시 불러오기')),
  );
}

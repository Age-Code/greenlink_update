import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';

class TutorQuizListScreen extends ConsumerWidget {
  const TutorQuizListScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyClass = ref.watch(studyClassProvider(classId)).asData?.value;
    final quizzes = ref.watch(allQuizzesProvider(classId));
    final action = ref.watch(quizActionControllerProvider);
    ref.listen(quizActionControllerProvider, (_, next) {
      next.whenOrNull(
        error: (_, _) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퀴즈 작업을 완료하지 못했어요.')),
        ),
      );
    });
    return AppResponsiveScaffold(
      menu:
          studyClass == null
              ? null
              : TutorClassMenu(
                studyClass: studyClass,
                selected: ClassMenuItem.quizzes,
              ),
      body: quizzes.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.coral),
        ),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(allQuizzesProvider(classId)),
            child: const Text('다시 불러오기'),
          ),
        ),
        data: (items) => _QuizListBody(
          classId: classId,
          quizzes: items,
          onCreate: () => context.push(AppRoutes.newTutorQuiz(classId)),
          actionDisabled: action.isLoading,
          onPublish: (quiz) => _publish(context, ref, quiz),
          onUnpublish: (quiz) => _unpublish(ref, quiz),
          onDelete: (quiz) => _delete(context, ref, quiz),
        ),
      ),
    );
  }

  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    StudyQuiz quiz,
  ) async {
    final error = await ref.read(quizActionControllerProvider.notifier).publish(
          classId: classId,
          quizId: quiz.id,
        );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _unpublish(WidgetRef ref, StudyQuiz quiz) {
    return ref.read(quizActionControllerProvider.notifier).setStatus(
          classId: classId,
          quizId: quiz.id,
          status: QuizStatus.draft,
        );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    StudyQuiz quiz,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퀴즈를 삭제할까요?'),
        content: Text('${quiz.title} 및 모든 문제가 삭제됩니다.'),
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
    await ref.read(quizActionControllerProvider.notifier).deleteQuiz(
          classId: classId,
          quizId: quiz.id,
        );
  }
}

class _QuizListBody extends StatelessWidget {
  const _QuizListBody({
    required this.classId,
    required this.quizzes,
    required this.onCreate,
    required this.actionDisabled,
    required this.onPublish,
    required this.onUnpublish,
    required this.onDelete,
  });

  final String classId;
  final List<StudyQuiz> quizzes;
  final VoidCallback onCreate;
  final bool actionDisabled;
  final ValueChanged<StudyQuiz> onPublish;
  final ValueChanged<StudyQuiz> onUnpublish;
  final ValueChanged<StudyQuiz> onDelete;

  @override
  Widget build(BuildContext context) => AppPageBody(
    children: [
      AppPageHeading(
        title: '퀴즈',
        subtitle: '학습 내용을 확인할 문제를 만들어보세요.',
        action: AppHeadingButton(
          label: '새 퀴즈',
          onPressed: actionDisabled ? null : onCreate,
        ),
      ),
      const SizedBox(height: 26),
      if (quizzes.isEmpty)
        const _EmptyQuizzes()
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
              for (var index = 0; index < quizzes.length; index++) ...[
                _QuizRow(
                  classId: classId,
                  quiz: quizzes[index],
                  disabled: actionDisabled,
                  onPublish: () => onPublish(quizzes[index]),
                  onUnpublish: () => onUnpublish(quizzes[index]),
                  onDelete: () => onDelete(quizzes[index]),
                ),
                if (index < quizzes.length - 1)
                  const Divider(height: 1, color: AppColors.homeDivider),
              ],
            ],
          ),
        ),
    ],
  );
}

class _QuizRow extends StatelessWidget {
  const _QuizRow({
    required this.classId,
    required this.quiz,
    required this.disabled,
    required this.onPublish,
    required this.onUnpublish,
    required this.onDelete,
  });

  final String classId;
  final StudyQuiz quiz;
  final bool disabled;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutes.editTutorQuiz(classId, quiz.id)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title.isEmpty ? '제목 없는 퀴즈' : quiz.title,
                  style: const TextStyle(
                    color: AppColors.homeInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${quiz.questionCount}문제',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    _StatusBadge(status: quiz.status),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !disabled,
            onSelected: (value) {
              if (value == 'edit') {
                context.push(AppRoutes.editTutorQuiz(classId, quiz.id));
              }
              if (value == 'publish') onPublish();
              if (value == 'unpublish') onUnpublish();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              if (quiz.status == QuizStatus.draft)
                const PopupMenuItem(value: 'publish', child: Text('게시'))
              else
                const PopupMenuItem(value: 'unpublish', child: Text('게시 취소')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('삭제', style: TextStyle(color: AppColors.coralDark)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final QuizStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: status == QuizStatus.published
          ? const Color(0xFFE5F4EA)
          : AppColors.softGray,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status == QuizStatus.published ? '게시됨' : '작성 중',
      style: TextStyle(
        color: status == QuizStatus.published
            ? const Color(0xFF277A45)
            : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmptyQuizzes extends StatelessWidget {
  const _EmptyQuizzes();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 72),
    child: Column(
      children: [
        Icon(Icons.quiz_outlined, size: 38, color: AppColors.textFaint),
        SizedBox(height: 12),
        Text(
          '아직 만든 퀴즈가 없어요.\n새 퀴즈를 만들어 학습 내용을 확인해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      ],
    ),
  );
}

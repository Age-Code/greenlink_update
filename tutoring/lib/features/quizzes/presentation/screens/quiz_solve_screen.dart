import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/core/widgets/primary_button.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_session_widgets.dart';

/// 08_Quiz_Solve / 09_Quiz_Feedback. Focus mode: no class menu, the step
/// counter and progress bar live in the top bar, actions in the bottom bar.
class QuizSolveScreen extends ConsumerWidget {
  const QuizSolveScreen({
    super.key,
    required this.classId,
    required this.quizId,
  });

  final String classId;
  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final args = (
      userId: user.uid,
      classId: classId,
      quizId: quizId,
      questionId: null,
      noteId: null,
    );
    final provider = quizSessionControllerProvider(args);
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final completionTarget = _relatedNote(session);
    final showProgress =
        !session.isLoading && !session.isComplete && session.questions.isNotEmpty;

    return AppResponsiveScaffold(
      appBar: AppTopBar(
        leading: IconButton(
          tooltip: '나가기',
          onPressed: () => _close(context, session),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (showProgress)
            QuizSessionCounter(
              current: session.currentQuestionIndex + 1,
              total: session.questions.length,
            ),
        ],
        bottom:
            showProgress
                ? QuizSessionProgressBar(
                  value:
                      (session.currentQuestionIndex + 1) /
                      session.questions.length,
                )
                : null,
      ),
      bottomBar: _bottomBar(context, session, controller),
      body:
          session.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.coral),
              )
              : session.errorMessage != null && session.questions.isEmpty
              ? _LoadError(
                message: session.errorMessage!,
                onExit: () => context.pop(),
              )
              : session.isComplete
              ? _Completion(
                correctCount: session.correctCount,
                totalQuestions: session.questions.length,
                onList: () => context.go(AppRoutes.tuteeQuizzes(classId)),
                onRelatedNote:
                    completionTarget == null
                        ? null
                        : () => context.push(
                          AppRoutes.noteReader(
                            classId,
                            completionTarget.noteId,
                            targetBlockId: completionTarget.blockId,
                          ),
                        ),
              )
              : QuizSessionQuestionPage(
                classId: classId,
                session: session,
                controller: controller,
              ),
    );
  }

  /// Before checking: [정답 확인]. After: [오답 노트] + [다음 문제 →].
  Widget? _bottomBar(
    BuildContext context,
    QuizSessionState session,
    QuizSessionController controller,
  ) {
    if (session.isLoading ||
        session.isComplete ||
        session.currentQuestion == null) {
      return null;
    }
    if (!session.isAnswerChecked) {
      return PrimaryButton(
        label: '정답 확인',
        height: 56,
        onPressed:
            session.selectedAnswer == null ? null : controller.checkAnswer,
      );
    }
    final isLast =
        session.currentQuestionIndex == session.questions.length - 1;
    return Row(
      children: [
        _ReviewNoteButton(
          iconOnly: context.screenType == ScreenType.mobile,
          onPressed: () => context.push(AppRoutes.classReview(classId)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PrimaryButton(
            label: isLast ? '퀴즈 완료' : '다음 문제',
            icon: Icons.arrow_forward,
            height: 56,
            isLoading: session.isSubmitting,
            onPressed: controller.next,
          ),
        ),
      ],
    );
  }

  _RelatedNoteTarget? _relatedNote(QuizSessionState session) {
    for (final question in session.questions) {
      final noteId = question.relatedNoteId;
      if (noteId != null && noteId.isNotEmpty) {
        return (noteId: noteId, blockId: question.relatedBlockId);
      }
    }
    return null;
  }

  Future<void> _close(BuildContext context, QuizSessionState session) async {
    if (session.answers.isEmpty || session.isComplete) {
      context.pop();
      return;
    }
    final close = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('퀴즈를 나갈까요?'),
            content: const Text('아직 완료하지 않은 풀이 내용은 저장되지 않아요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 풀기'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
    );
    if (close == true && context.mounted) context.pop();
  }
}

typedef _RelatedNoteTarget = ({String noteId, String? blockId});

/// White outlined "오답 노트" button; icon only on mobile.
class _ReviewNoteButton extends StatelessWidget {
  const _ReviewNoteButton({required this.iconOnly, required this.onPressed});

  final bool iconOnly;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.homeInk,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      minimumSize: const Size(56, 56),
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 20),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    if (iconOnly) {
      return Tooltip(
        message: '오답 노트',
        child: OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: const Icon(Icons.edit_note, size: 24),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: const Icon(Icons.edit_note, size: 20),
      label: const Text('오답 노트'),
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion({
    required this.correctCount,
    required this.totalQuestions,
    required this.onList,
    required this.onRelatedNote,
  });

  final int correctCount;
  final int totalQuestions;
  final VoidCallback onList;
  final VoidCallback? onRelatedNote;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppLayout.horizontalPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.sage,
              child: Icon(Icons.check, size: 34, color: AppColors.sageDark),
            ),
            const SizedBox(height: 20),
            const Text(
              '퀴즈를 완료했어요.',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '$totalQuestions문제 중 $correctCount문제를 이해했어요.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onList,
                child: const Text('퀴즈 목록으로'),
              ),
            ),
            if (onRelatedNote != null) ...[
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRelatedNote,
                  child: const Text('관련 노트 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onExit});

  final String message;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        TextButton(onPressed: onExit, child: const Text('목록으로 돌아가기')),
      ],
    ),
  );
}

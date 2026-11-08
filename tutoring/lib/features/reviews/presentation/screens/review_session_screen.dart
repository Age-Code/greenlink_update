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
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_question_card.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_session_widgets.dart';

/// 12_Review_Retry: solve the given review items again. A correct answer
/// marks the item reviewed; a miss keeps it pending and counts up.
class ReviewSessionScreen extends ConsumerWidget {
  const ReviewSessionScreen({
    super.key,
    required this.classId,
    required this.reviewIds,
  });

  final String classId;
  final List<String> reviewIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    if (reviewIds.isEmpty) {
      return AppResponsiveScaffold(
        leading: _BackButton(onPressed: () => _leave(context)),
        title: const Text('복습'),
        body: _Notice(
          icon: Icons.check_circle_outline,
          title: '복습할 문제가 없어요.',
          message: '복습 목록에서 다시 확인할 문제를 골라주세요.',
          actionLabel: '복습 목록으로',
          onAction: () => _leave(context),
        ),
      );
    }

    final args = (
      userId: user.uid,
      classId: classId,
      reviewIds: reviewIds.join(','),
    );
    final provider = reviewSessionControllerProvider(args);
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final showProgress =
        !session.isLoading && !session.isComplete && session.questions.isNotEmpty;

    return AppResponsiveScaffold(
      appBar: AppTopBar(
        leading: _BackButton(onPressed: () => _close(context, session)),
        title: const Text('복습'),
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
      bottomBar: _bottomBar(session, controller),
      body:
          session.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.coral),
              )
              : session.errorMessage != null && session.questions.isEmpty
              ? _Notice(
                icon: Icons.cloud_off_outlined,
                title: session.errorMessage!,
                message: '문제가 삭제되었거나 비공개로 바뀌었을 수 있어요.',
                actionLabel: '복습 목록으로',
                onAction: () => _leave(context),
              )
              : session.isComplete
              ? _Summary(
                total: session.questions.length,
                recovered: session.correctCount,
                onList: () => _leave(context),
              )
              : QuizSessionQuestionPage(
                classId: classId,
                session: session,
                controller: controller,
                mode: QuizSessionMode.review,
              ),
    );
  }

  Widget? _bottomBar(QuizSessionState session, QuizSessionController controller) {
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
    return PrimaryButton(
      label: isLast ? '결과 보기' : '다음 복습',
      icon: Icons.arrow_forward,
      height: 56,
      isLoading: session.isSubmitting,
      onPressed: controller.next,
    );
  }

  /// Back to the review list; the list stream already reflects any status
  /// change made during the session.
  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.classReview(classId));
    }
  }

  Future<void> _close(BuildContext context, QuizSessionState session) async {
    if (session.answers.isEmpty || session.isComplete) {
      _leave(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('복습을 그만둘까요?'),
            content: const Text(
              '이미 푼 문제의 상태는 저장돼요. 남은 문제는 복습 목록에 그대로 있어요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 풀기'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('그만두기'),
              ),
            ],
          ),
    );
    if (leave == true && context.mounted) _leave(context);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '돌아가기',
    onPressed: onPressed,
    icon: const Icon(Icons.arrow_back),
  );
}

/// End-of-session summary before returning to the list.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.recovered,
    required this.onList,
  });

  final int total;
  final int recovered;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    final remaining = total - recovered;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.horizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor:
                    remaining == 0 ? AppColors.sage : AppColors.coralSoft,
                child: Icon(
                  remaining == 0 ? Icons.check : Icons.replay,
                  size: 34,
                  color:
                      remaining == 0 ? AppColors.sageDark : AppColors.coralDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '복습을 마쳤어요.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '$total문제 중 $recovered문제를 다시 확인했어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              if (remaining > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '$remaining문제는 복습 목록에 남아 있어요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.coralDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onList,
                  child: const Text('복습 목록으로'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.textFaint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.homeInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_question_card.dart';

/// One-question Quick Check embedded in a note. Shares the session
/// controller with the quiz screen, so wrong answers reach the review list
/// the same way; its buttons stay inline because there is no bottom bar.
class QuickCheckSolver extends ConsumerWidget {
  const QuickCheckSolver({
    super.key,
    required this.classId,
    required this.quizId,
    required this.questionId,
    required this.noteId,
  });

  final String classId;
  final String quizId;
  final String questionId;
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
    }
    final args = (
      userId: user.uid,
      classId: classId,
      quizId: quizId,
      questionId: questionId,
      noteId: noteId,
    );
    final provider = quizSessionControllerProvider(args);
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    if (session.isLoading) {
      return const LinearProgressIndicator(
        minHeight: 2,
        color: AppColors.coral,
      );
    }
    final question = session.currentQuestion;
    if (question == null) {
      return Text(
        session.errorMessage ?? 'Quick Check를 불러오지 못했어요.',
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }
    final relatedNoteId = question.relatedNoteId;
    final String? targetNoteId =
        relatedNoteId == null || relatedNoteId.isEmpty ? null : relatedNoteId;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    final Widget button =
        !session.isAnswerChecked
            ? FilledButton.icon(
              onPressed:
                  session.selectedAnswer == null
                      ? null
                      : controller.checkAnswer,
              style: buttonStyle,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('정답 확인'),
            )
            : FilledButton(
              onPressed:
                  session.isSubmitting || session.isComplete
                      ? null
                      : controller.next,
              style: buttonStyle,
              child:
                  session.isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(session.isComplete ? '저장됨' : '결과 저장'),
            );
    // Figma 06 keeps the action small and at the right of the card.
    final footer = Align(alignment: Alignment.centerRight, child: button);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizQuestionCard(
          question: question,
          selectedAnswer: session.selectedAnswer,
          isAnswerChecked: session.isAnswerChecked,
          onSelectAnswer: controller.selectAnswer,
          showQuestionLabel: false,
          compact: true,
          isReviewSaved: session.isReviewSaved,
          isReviewSaveFailed: session.isReviewSaveFailed,
          onRelatedNote:
              targetNoteId == null
                  ? null
                  : () => context.push(
                    AppRoutes.noteReader(
                      classId,
                      targetNoteId,
                      targetBlockId: question.relatedBlockId,
                    ),
                  ),
          footer: footer,
        ),
        if (session.errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            session.errorMessage!,
            style: const TextStyle(color: AppColors.coralDark),
          ),
          TextButton(
            onPressed: controller.retrySubmit,
            child: const Text('결과 저장 다시 시도'),
          ),
        ],
      ],
    );
  }
}

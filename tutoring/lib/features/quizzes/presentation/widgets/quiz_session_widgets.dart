import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_question_card.dart';

/// Pieces shared by the quiz run (08/09) and the review retry (12) screens.

/// Thin 4px progress strip under the top bar.
class QuizSessionProgressBar extends StatelessWidget
    implements PreferredSizeWidget {
  const QuizSessionProgressBar({super.key, required this.value});

  final double value;

  @override
  Size get preferredSize => const Size.fromHeight(4);

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: value,
    minHeight: 4,
    color: AppColors.coral,
    backgroundColor: AppColors.coralSoft,
  );
}

/// "n / m" step counter for the top bar.
class QuizSessionCounter extends StatelessWidget {
  const QuizSessionCounter({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Text(
    '$current / $total',
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];
const _numpadKeys = [
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
];

/// The current question with keyboard shortcuts (1–4 select, Enter checks or
/// moves on), the related-note lookup and the submit-error retry line.
class QuizSessionQuestionPage extends ConsumerWidget {
  const QuizSessionQuestionPage({
    super.key,
    required this.classId,
    required this.session,
    required this.controller,
    this.mode = QuizSessionMode.quiz,
  });

  final String classId;
  final QuizSessionState session;
  final QuizSessionController controller;
  final QuizSessionMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = session.currentQuestion!;
    final relatedNoteId = question.relatedNoteId;
    final String? noteId =
        relatedNoteId == null || relatedNoteId.isEmpty ? null : relatedNoteId;
    final relatedNoteTitle =
        noteId == null
            ? null
            : ref
                .watch(noteProvider((classId: classId, noteId: noteId)))
                .asData
                ?.value
                ?.title;

    void advance() {
      if (session.isAnswerChecked) {
        controller.next();
      } else {
        controller.checkAnswer();
      }
    }

    final bindings = <ShortcutActivator, VoidCallback>{
      for (
        var index = 0;
        index < question.options.length && index < _digitKeys.length;
        index++
      ) ...{
        SingleActivator(_digitKeys[index]): () => controller.selectAnswer(index),
        SingleActivator(_numpadKeys[index]):
            () => controller.selectAnswer(index),
      },
      const SingleActivator(LogicalKeyboardKey.enter): advance,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): advance,
    };

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        autofocus: true,
        child: AppPageBody(
          bottom: 32,
          children: [
            QuizQuestionCard(
              question: question,
              selectedAnswer: session.selectedAnswer,
              isAnswerChecked: session.isAnswerChecked,
              onSelectAnswer: controller.selectAnswer,
              questionNumber: session.currentQuestionIndex + 1,
              mode: mode,
              topicLabel: session.topicsByQuestionId[question.id],
              isReviewSaved: session.isReviewSaved,
              isReviewSaveFailed: session.isReviewSaveFailed,
              relatedNoteTitle: relatedNoteTitle,
              onRelatedNote:
                  noteId == null
                      ? null
                      : () => context.push(
                        AppRoutes.noteReader(
                          classId,
                          noteId,
                          targetBlockId: question.relatedBlockId,
                        ),
                      ),
            ),
            if (session.errorMessage != null) ...[
              const SizedBox(height: 12),
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
        ),
      ),
    );
  }
}

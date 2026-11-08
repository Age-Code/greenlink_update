import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_feedback_card.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_option_tile.dart';

/// Which flow a question card belongs to; it only changes labels and texts.
enum QuizSessionMode { quiz, review }

/// Question, four options and (after checking) the feedback card.
///
/// Buttons are not part of the card: the quiz screen pins them in its bottom
/// bar, while an inline Quick Check passes them through [footer].
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswerChecked,
    required this.onSelectAnswer,
    this.questionNumber,
    this.showQuestionLabel = true,
    this.mode = QuizSessionMode.quiz,
    this.topicLabel,
    this.isReviewSaved = false,
    this.isReviewSaveFailed = false,
    this.relatedNoteTitle,
    this.onRelatedNote,
    this.footer,
    this.compact = false,
  });

  final QuizQuestion question;
  final int? selectedAnswer;
  final bool isAnswerChecked;
  final ValueChanged<int> onSelectAnswer;

  /// One-based number shown as "QUESTION n".
  final int? questionNumber;
  final bool showQuestionLabel;
  final QuizSessionMode mode;

  /// Review retry: topic shown in the "다시 풀기 · 주제" chip.
  final String? topicLabel;
  final bool isReviewSaved;
  final bool isReviewSaveFailed;
  final String? relatedNoteTitle;
  final VoidCallback? onRelatedNote;
  final Widget? footer;

  /// Inline Quick Check: smaller prompt and a tighter gap to the options.
  final bool compact;

  bool get isCorrect => selectedAnswer == question.correctOptionIndex;

  QuizOptionState _stateFor(int index) {
    final selected = selectedAnswer == index;
    if (!isAnswerChecked) {
      return selected ? QuizOptionState.selected : QuizOptionState.idle;
    }
    if (index == question.correctOptionIndex) return QuizOptionState.correct;
    if (selected) return QuizOptionState.wrong;
    return QuizOptionState.muted;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showQuestionLabel) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                questionNumber == null
                    ? 'QUESTION'
                    : 'QUESTION $questionNumber',
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (mode == QuizSessionMode.review)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  topicLabel == null || topicLabel!.isEmpty
                      ? '다시 풀기'
                      : '다시 풀기 · $topicLabel',
                  style: const TextStyle(
                    color: AppColors.homeSageDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              const Text(
                '객관식',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
      ],
      InlineCodeText(
        question.prompt,
        style:
            compact
                ? const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                )
                : const TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 24,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
      ),
      SizedBox(height: compact ? 16 : 24),
      for (var index = 0; index < question.options.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        QuizOptionTile(
          index: index,
          label: question.options[index],
          state: _stateFor(index),
          onTap: isAnswerChecked ? null : () => onSelectAnswer(index),
        ),
      ],
      if (isAnswerChecked) ...[
        const SizedBox(height: 24),
        QuizFeedbackCard(
          mode: mode,
          correct: isCorrect,
          explanation: question.explanation,
          reviewSaved:
              isReviewSaved && (!isCorrect || mode == QuizSessionMode.review),
          reviewSaveFailed:
              isReviewSaveFailed &&
              (!isCorrect || mode == QuizSessionMode.review),
          relatedNoteTitle: relatedNoteTitle,
          onRelatedNote: onRelatedNote,
        ),
      ],
      if (footer != null) ...[const SizedBox(height: 16), footer!],
    ],
  );
}

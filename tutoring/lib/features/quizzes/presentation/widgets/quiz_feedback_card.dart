import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/quiz_question_card.dart';

/// Explanation card shown after an answer is checked (09_Quiz_Feedback).
class QuizFeedbackCard extends StatelessWidget {
  const QuizFeedbackCard({
    super.key,
    this.mode = QuizSessionMode.quiz,
    required this.correct,
    required this.explanation,
    this.reviewSaved = false,
    this.reviewSaveFailed = false,
    this.relatedNoteTitle,
    this.onRelatedNote,
  });

  final QuizSessionMode mode;
  final bool correct;
  final String explanation;

  bool get _isReview => mode == QuizSessionMode.review;

  String get _title {
    if (!correct) return '한 번 더 확인해볼까요?';
    return _isReview ? '이제 이해했어요!' : '잘했어요!';
  }

  String get _savedMessage {
    if (!_isReview) return '복습 목록에 자동으로 추가했어요.';
    return correct
        ? "개념을 올바르게 확인했어요. 이 문제를 '다시 확인함'으로 바꿨어요."
        : '복습 목록에 그대로 남아요. 다음에 다시 만나요.';
  }

  /// Shows the "복습 목록에 자동으로 추가했어요" line.
  final bool reviewSaved;

  /// Shows the "복습 목록에 저장하지 못했어요" line instead.
  final bool reviewSaveFailed;

  final String? relatedNoteTitle;
  final VoidCallback? onRelatedNote;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A211B19),
          offset: Offset(0, 2),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: correct ? AppColors.homeSage : AppColors.homePeach,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                correct ? Icons.check : Icons.lightbulb_outline,
                size: 16,
                color: correct ? AppColors.homeSageDark : AppColors.homeBrown,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _title,
                style: const TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_isReview && correct && reviewSaved)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '기억 복구됨',
                  style: TextStyle(
                    color: AppColors.homeSageDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ExplanationBody(explanation),
        if (reviewSaved || reviewSaveFailed) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: reviewSaved ? AppColors.softGray : AppColors.coralSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  reviewSaved
                      ? (_isReview && correct
                          ? Icons.check_circle_outline
                          : Icons.bookmark)
                      : Icons.error_outline,
                  size: 14,
                  color:
                      reviewSaved
                          ? (_isReview && correct
                              ? AppColors.homeSageDark
                              : AppColors.homeBrown)
                          : AppColors.coralDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reviewSaved
                        ? _savedMessage
                        : '복습 목록에 저장하지 못했어요. 네트워크나 권한을 확인해주세요.',
                    style: TextStyle(
                      color:
                          reviewSaved
                              ? AppColors.textSecondary
                              : AppColors.coralDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (onRelatedNote != null) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 14,
                color: AppColors.homeMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '관련 학습: ${relatedNoteTitle ?? '관련 노트'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.homeMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRelatedNote,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('관련 노트 보기 →'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

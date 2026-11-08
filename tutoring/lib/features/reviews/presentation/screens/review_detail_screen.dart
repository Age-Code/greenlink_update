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
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';

/// 11_Review_Detail: one wrong answer, the correct one, the explanation and
/// the related note. Focus mode without the class menu.
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({
    super.key,
    required this.classId,
    required this.reviewId,
  });

  final String classId;
  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final key = (userId: user.uid, classId: classId, reviewId: reviewId);
    final detail = ref.watch(reviewDetailProvider(key));
    final loaded = detail.asData?.value;

    return AppResponsiveScaffold(
      leading: IconButton(
        tooltip: '돌아가기',
        onPressed: () => _goBack(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: _TopicTitle(title: loaded?.item.topic ?? '오답 다시보기'),
      actions: [
        if (loaded != null)
          PopupMenuButton<_DetailAction>(
            tooltip: '더보기',
            onSelected: (action) => _onAction(context, ref, key, action),
            itemBuilder:
                (context) => [
                  if (loaded.item.needsReview)
                    const PopupMenuItem(
                      value: _DetailAction.markReviewed,
                      child: Text('다시 확인함으로 표시'),
                    ),
                  const PopupMenuItem(
                    value: _DetailAction.delete,
                    child: Text('목록에서 삭제'),
                  ),
                ],
            icon: const Icon(Icons.more_vert),
          ),
      ],
      bottomBar:
          loaded == null
              ? null
              : PrimaryButton(
                label: '다시 풀어보기',
                icon: Icons.replay,
                height: 56,
                onPressed:
                    loaded.hasQuestion
                        ? () => context.push(
                          AppRoutes.reviewSession(
                            classId,
                            ids: [loaded.item.id],
                          ),
                        )
                        : null,
              ),
      body: detail.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
        error:
            (_, _) => _Notice(
              title: '복습 항목을 불러오지 못했어요.',
              message: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
              actionLabel: '다시 시도',
              onAction: () => ref.invalidate(reviewDetailProvider(key)),
            ),
        data:
            (value) =>
                value == null
                    ? _Notice(
                      title: '복습 항목을 찾을 수 없어요.',
                      message: '이미 삭제되었거나 다른 계정의 항목이에요.',
                      actionLabel: '복습 목록으로',
                      onAction: () => _goBack(context),
                    )
                    : _DetailBody(classId: classId, detail: value),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.classReview(classId));
    }
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    ReviewDetailKey key,
    _DetailAction action,
  ) async {
    final repository = ref.read(reviewRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _DetailAction.markReviewed:
        try {
          await repository.markReviewed(
            userId: key.userId,
            reviewId: key.reviewId,
          );
          ref.invalidate(reviewDetailProvider(key));
          messenger.showSnackBar(
            const SnackBar(content: Text('다시 확인함으로 표시했어요.')),
          );
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('상태를 바꾸지 못했어요. 다시 시도해주세요.')),
          );
        }
      case _DetailAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('복습 목록에서 삭제할까요?'),
                content: const Text('이 문제를 다시 틀리면 목록에 새로 추가돼요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
        );
        if (confirmed != true) return;
        try {
          await repository.deleteReview(
            userId: key.userId,
            reviewId: key.reviewId,
          );
          if (context.mounted) _goBack(context);
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')),
          );
        }
    }
  }
}

enum _DetailAction { markReviewed, delete }

class _TopicTitle extends StatelessWidget {
  const _TopicTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.homeBrown),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.classId, required this.detail});

  final String classId;
  final ReviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    final note = detail.relatedNote;
    final question = detail.question;
    final weekLabel =
        note == null
            ? '복습'
            : '복습 · Week ${note.week.toString().padLeft(2, '0')}';
    return AppPageBody(
      bottom: AppSpacing.xxl,
      children: [
        Row(
          children: [
            Text(
              weekLabel,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.35,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text(
              '오답 다시보기',
              style: TextStyle(color: AppColors.homeMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        InlineCodeText(
          question?.prompt ?? item.prompt,
          style: const TextStyle(
            color: AppColors.homeInk,
            fontSize: 24,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (question == null)
          _QuestionGoneCard(selectedIndex: item.lastSelectedOptionIndex)
        else ...[
          _AnswerComparison(
            selectedLabel: detail.selectedOptionLabel ?? '기록 없음',
            correctLabel: detail.correctOptionLabel ?? '기록 없음',
          ),
          const SizedBox(height: AppSpacing.xl),
          _ExplanationCard(
            explanation: question.explanation,
            wrongCount: item.wrongCount,
            needsReview: item.needsReview,
          ),
        ],
        if (item.noteId != null && item.noteId!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _RelatedNoteCard(
            noteTitle: note?.title,
            onOpen:
                note == null
                    ? null
                    : () => context.push(
                      AppRoutes.noteReader(
                        classId,
                        note.id,
                        targetBlockId: item.blockId,
                      ),
                    ),
          ),
        ],
      ],
    );
  }
}

/// "이전에 선택한 답" and "정답" cells: side by side from tablet up, stacked on
/// mobile.
class _AnswerComparison extends StatelessWidget {
  const _AnswerComparison({
    required this.selectedLabel,
    required this.correctLabel,
  });

  final String selectedLabel;
  final String correctLabel;

  @override
  Widget build(BuildContext context) {
    final stacked = context.screenType == ScreenType.mobile;
    final selected = _AnswerCell(
      key: const Key('answer-selected'),
      caption: '이전에 선택한 답',
      chip: '오답',
      label: selectedLabel,
      correct: false,
    );
    final correct = _AnswerCell(
      key: const Key('answer-correct'),
      caption: '정답',
      chip: '정답',
      label: correctLabel,
      correct: true,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(16),
      child:
          stacked
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selected,
                  const Divider(height: AppSpacing.xxl, color: AppColors.border),
                  correct,
                ],
              )
              : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: selected),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: VerticalDivider(width: 1, color: AppColors.border),
                    ),
                    Expanded(child: correct),
                  ],
                ),
              ),
    );
  }
}

class _AnswerCell extends StatelessWidget {
  const _AnswerCell({
    super.key,
    required this.caption,
    required this.chip,
    required this.label,
    required this.correct,
  });

  final String caption;
  final String chip;
  final String label;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final accent = correct ? AppColors.homeSageDark : AppColors.homeBrown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                caption,
                style: TextStyle(
                  color: correct ? AppColors.homeSageDark : AppColors.homeMuted,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: correct ? AppColors.sage : AppColors.coralSoft,
                border: Border.all(
                  color:
                      correct
                          ? AppColors.sageDark.withValues(alpha: 0.4)
                          : AppColors.coral.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: correct ? AppColors.homeSage : AppColors.noteMemo,
              border: Border.all(
                color:
                    correct
                        ? AppColors.sageDark.withValues(alpha: 0.5)
                        : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InlineCodeText(
              label,
              style: TextStyle(
                color: AppColors.homeInk,
                fontSize: 16,
                height: 1.5,
                fontWeight: correct ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.explanation,
    required this.wrongCount,
    required this.needsReview,
  });

  final String explanation;
  final int wrongCount;
  final bool needsReview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: _cardDecoration(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: AppColors.homeBrown),
            SizedBox(width: AppSpacing.xs),
            Text(
              '해설 및 핵심 개념',
              style: TextStyle(
                color: AppColors.homeInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ExplanationBody(explanation),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.tips_and_updates_outlined,
              size: 16,
              color: AppColors.homeMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                needsReview
                    ? '지금까지 $wrongCount번 틀린 문제예요. 다시 풀어 맞히면 "다시 확인함"으로 바뀌어요.'
                    : '이미 다시 확인한 문제예요. 한 번 더 풀어보면 더 오래 기억에 남아요.',
                style: const TextStyle(
                  color: AppColors.homeMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuestionGoneCard extends StatelessWidget {
  const _QuestionGoneCard({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.coralSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.coralDark),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '원본 문제를 더 이상 볼 수 없어요.',
                style: TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '튜터가 퀴즈를 삭제했거나 비공개로 바꿨어요. '
                '${selectedIndex >= 0 ? '이전에 선택한 답은 ${selectedIndex + 1}번이었어요.' : ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RelatedNoteCard extends StatelessWidget {
  const _RelatedNoteCard({required this.noteTitle, required this.onOpen});

  /// Null when the note was deleted or unpublished.
  final String? noteTitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      hoverColor: AppColors.softGray,
      mouseCursor:
          onOpen == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: AppColors.homeBrown,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '관련 학습 내용',
                    style: TextStyle(color: AppColors.homeMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noteTitle ?? '관련 노트를 더 이상 볼 수 없어요.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          noteTitle == null
                              ? AppColors.textSecondary
                              : AppColors.homeInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onOpen != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Text(
                '노트에서 확인 →',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

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
          const Icon(Icons.search_off, size: 36, color: AppColors.textFaint),
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

BoxDecoration _cardDecoration(double radius) => BoxDecoration(
  color: AppColors.surface,
  border: Border.all(color: AppColors.border),
  borderRadius: BorderRadius.circular(radius),
  boxShadow: const [
    BoxShadow(color: Color(0x08211B19), offset: Offset(0, 2), blurRadius: 12),
  ],
);

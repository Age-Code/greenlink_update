import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_menu.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_filter.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';
import 'package:tutoring/features/reviews/presentation/widgets/review_filter_chips.dart';
import 'package:tutoring/features/reviews/presentation/widgets/review_list_card.dart';
import 'package:tutoring/features/reviews/presentation/widgets/review_summary_card.dart';

const _classAssetRoot = 'assets/images/classes';

/// 10_Class_Review: the learner's wrong-answer list for one class.
class ClassReviewScreen extends ConsumerStatefulWidget {
  const ClassReviewScreen({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<ClassReviewScreen> createState() => _ClassReviewScreenState();
}

class _ClassReviewScreenState extends ConsumerState<ClassReviewScreen> {
  var _filter = ReviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final classId = widget.classId;
    final studyClass = ref.watch(studyClassProvider(classId)).asData?.value;
    final key = (userId: user.uid, classId: classId);
    final reviews = ref.watch(classReviewsProvider(key));

    return AppResponsiveScaffold(
      menu:
          studyClass == null
              ? null
              : StudentClassMenu(
                studyClass: studyClass,
                selected: ClassMenuItem.review,
              ),
      menuIcon: SvgPicture.asset('$_classAssetRoot/menu.svg', width: 18),
      title: _ClassTitle(title: studyClass?.title ?? '복습'),
      actions: [
        IconButton(
          tooltip: '더보기',
          onPressed:
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('클래스 설정은 다음 단계에서 연결할게요.')),
              ),
          icon: SvgPicture.asset('$_classAssetRoot/more.svg', height: 17),
        ),
      ],
      body: reviews.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
        error:
            (_, _) => _LoadError(
              onRetry: () => ref.invalidate(classReviewsProvider(key)),
            ),
        data:
            (items) =>
                items.isEmpty
                    ? _EmptyState(
                      onQuizzes:
                          () => context.push(AppRoutes.tuteeQuizzes(classId)),
                    )
                    : _ReviewList(
                      classId: classId,
                      items: orderReviews(items),
                      filter: _filter,
                      onFilter: (filter) => setState(() => _filter = filter),
                    ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.classId,
    required this.items,
    required this.filter,
    required this.onFilter,
  });

  final String classId;
  final List<ReviewItem> items;
  final ReviewFilter filter;
  final ValueChanged<ReviewFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final pending = ReviewFilter.needsReview.apply(items);
    final visible = filter.apply(items);
    return AppPageBody(
      children: [
        const AppPageHeading(title: '복습', subtitle: '헷갈렸던 내용을 다시 확인해보세요.'),
        const SizedBox(height: AppSpacing.xl),
        ReviewSummaryCard(
          pendingCount: pending.length,
          onStart:
              pending.isEmpty
                  ? null
                  : () => context.push(
                    AppRoutes.reviewSession(
                      classId,
                      ids: pending.map((item) => item.id),
                    ),
                  ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ReviewFilterChips(items: items, selected: filter, onChanged: onFilter),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text(
              '이 상태의 항목이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ReviewListCard(
            items: visible,
            onTap:
                (item) =>
                    context.push(AppRoutes.reviewDetail(classId, item.id)),
          ),
        const SizedBox(height: AppSpacing.xxl),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 14, color: AppColors.textFaint),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '개념 카드를 탭하면 필기와 실습 코드가 포함된 해설 시트로 이동합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textFaint, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Coral dot + class name, as in the Figma header.
class _ClassTitle extends StatelessWidget {
  const _ClassTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.coral,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.textFaint),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '복습 목록을 불러오지 못했어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            '네트워크 연결이나 Firestore 규칙 배포 상태를 확인해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onQuizzes});

  final VoidCallback onQuizzes;

  @override
  Widget build(BuildContext context) => AppPageBody(
    children: [
      const AppPageHeading(title: '복습', subtitle: '헷갈렸던 내용을 다시 확인해보세요.'),
      const SizedBox(height: 64),
      const CircleAvatar(
        radius: 34,
        backgroundColor: AppColors.sage,
        child: Icon(Icons.check, size: 34, color: AppColors.sageDark),
      ),
      const SizedBox(height: AppSpacing.lg),
      const Text(
        '복습할 내용이 없어요',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.homeInk,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      const Text(
        '퀴즈에서 틀린 문제가 여기에 모여요.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: AppSpacing.xl),
      Center(
        child: FilledButton.icon(
          onPressed: onQuizzes,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: AppColors.surface,
            minimumSize: const Size(0, AppLayout.minTouchHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.quiz_outlined, size: 18),
          label: const Text('퀴즈 풀러 가기'),
        ),
      ),
    ],
  );
}

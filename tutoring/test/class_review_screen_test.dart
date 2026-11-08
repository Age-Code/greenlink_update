import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_filter.dart';
import 'package:tutoring/features/reviews/presentation/screens/class_review_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

void main() {
  group('ReviewFilter', () {
    final items = sampleReviews();

    test('counts items per status', () {
      expect(ReviewFilter.all.count(items), 3);
      expect(ReviewFilter.needsReview.count(items), 2);
      expect(ReviewFilter.reviewed.count(items), 1);
      expect(ReviewFilter.needsReview.chipLabel(items), '복습 필요 (2)');
      expect(ReviewFilter.all.count(const []), 0);
    });

    test('orders pending items first, then newest change first', () {
      final ordered = orderReviews(items).map((item) => item.questionId);
      expect(ordered, ['question-1', 'question-2', 'question-3']);
    });
  });

  test('review session route carries the ids as one query value', () {
    final path = AppRoutes.reviewSession(
      'class-1',
      ids: ['class-1_quiz-1_question-1', 'class-1_quiz-1_question-2'],
    );
    final uri = Uri.parse(path);
    expect(uri.path, '/classes/class-1/review/session');
    expect(
      uri.queryParameters['ids'],
      'class-1_quiz-1_question-1,class-1_quiz-1_question-2',
    );
    expect(AppRoutes.reviewSession('class-1', ids: const []),
        '/classes/class-1/review/session');
    expect(
      AppRoutes.reviewDetail('class-1', 'class-1_quiz-1_question-1'),
      '/classes/class-1/review/class-1_quiz-1_question-1',
    );
  });

  Widget app({FakeReviewRepository? reviews}) => buildSignedInApp(
    home: const ClassReviewScreen(classId: 'class-1'),
    user: tuteeUser,
    reviews: reviews ?? FakeReviewRepository(sampleReviews()),
  );

  testAtScreenSizes(
    'review list shows the summary, chips and rows',
    app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('다시 확인할 내용이 2개 있어요.'), findsOneWidget);
      expect(find.text('복습 시작하기'), findsOneWidget);
      expect(find.text('전체 (3)'), findsOneWidget);
      expect(find.text('복습 필요 (2)'), findsOneWidget);
      expect(find.text('다시 확인함 (1)'), findsOneWidget);
      expect(find.text('존재하지 않는 key 조회하기'), findsOneWidget);
      expect(find.text('DICTIONARY'), findsOneWidget);
      expect(find.text('복습 필요'), findsNWidgets(2));
      expect(find.text('다시 확인함'), findsOneWidget);
    },
  );

  testWidgets('chips filter the rows and reviewed rows are dimmed', (
    tester,
  ) async {
    await tester.pumpAtSize(app(), TestScreenSizes.tablet);
    final reviewedTitle = find.text('for문의 기본 구조 및 range()');
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: reviewedTitle, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.7);

    await tester.tap(find.text('다시 확인함 (1)'));
    await tester.pump();
    expect(reviewedTitle, findsOneWidget);
    expect(find.text('존재하지 않는 key 조회하기'), findsNothing);

    await tester.tap(find.text('복습 필요 (2)'));
    await tester.pump();
    expect(reviewedTitle, findsNothing);
    expect(find.text('Tuple의 특징 (불변성)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all reviewed: summary says done and start is disabled', (
    tester,
  ) async {
    final reviews = FakeReviewRepository([
      sampleReview(
        questionId: 'question-3',
        topic: '반복문',
        prompt: 'for문의 기본 구조 및 range()',
        status: sampleReviews().last.status,
      ),
    ]);
    await tester.pumpAtSize(app(reviews: reviews), TestScreenSizes.phone);
    expect(find.text('다시 확인할 내용을 모두 확인했어요.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('복습 시작하기'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testAtScreenSizes(
    'empty state invites the learner to the quizzes',
    () => app(reviews: FakeReviewRepository()),
    verify: (tester, size) async {
      expect(find.text('복습할 내용이 없어요'), findsOneWidget);
      expect(find.text('퀴즈 풀러 가기'), findsOneWidget);
      expect(find.text('복습 시작하기'), findsNothing);
    },
  );
}

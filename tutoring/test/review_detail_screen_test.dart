import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';
import 'package:tutoring/features/reviews/presentation/screens/review_detail_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

void main() {
  const reviewId = 'class-1_quiz-1_question-1';

  Widget app({
    FakeReviewRepository? reviews,
    List<dynamic>? quizzes,
    List<dynamic>? questions,
    String id = reviewId,
  }) => buildSignedInApp(
    home: ReviewDetailScreen(classId: 'class-1', reviewId: id),
    user: tuteeUser,
    reviews: reviews ?? FakeReviewRepository(sampleReviews()),
    quizzes: quizzes?.cast(),
    questions: questions?.cast(),
  );

  testAtScreenSizes(
    'shows both answers, the explanation and the related note',
    app,
    verify: (tester, size) async {
      expect(find.text('복습 · Week 03'), findsOneWidget);
      expect(find.text('오답 다시보기'), findsOneWidget);
      expect(find.text('data[key]'), findsWidgets);
      expect(find.text('data.get(key)'), findsOneWidget);
      expect(find.text('이전에 선택한 답'), findsOneWidget);
      expect(find.text('오답'), findsOneWidget);
      expect(find.text('해설 및 핵심 개념'), findsOneWidget);
      expect(find.byType(ExplanationCodeCard), findsOneWidget);
      expect(find.text('Week 3 · 딕셔너리와 집합 자료형 정리'), findsOneWidget);
      expect(find.text('노트에서 확인 →'), findsOneWidget);
      expect(find.textContaining('1번 틀린 문제예요'), findsOneWidget);

      final selectedTop = tester.getTopLeft(find.byKey(const Key('answer-selected')));
      final correctTop = tester.getTopLeft(find.byKey(const Key('answer-correct')));
      if (size.width < 600) {
        expect(correctTop.dy, greaterThan(selectedTop.dy));
        expect(correctTop.dx, selectedTop.dx);
      } else {
        expect(correctTop.dy, selectedTop.dy);
        expect(correctTop.dx, greaterThan(selectedTop.dx));
      }

      final retry = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('다시 풀어보기'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      expect(retry.onPressed, isNotNull);
    },
  );

  testWidgets('a deleted question shows a notice and disables retry', (
    tester,
  ) async {
    await tester.pumpAtSize(app(questions: const []), TestScreenSizes.tablet);
    expect(find.text('원본 문제를 더 이상 볼 수 없어요.'), findsOneWidget);
    expect(find.textContaining('이전에 선택한 답은 1번이었어요.'), findsOneWidget);
    expect(find.text('존재하지 않는 key 조회하기'), findsOneWidget);
    expect(find.text('해설 및 핵심 개념'), findsNothing);
    expect(find.text('노트에서 확인 →'), findsOneWidget);
    final retry = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('다시 풀어보기'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(retry.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unpublished quiz counts as unavailable', (tester) async {
    await tester.pumpAtSize(
      app(quizzes: [sampleQuiz(id: 'quiz-1', status: QuizStatus.draft)]),
      TestScreenSizes.tablet,
    );
    expect(find.text('원본 문제를 더 이상 볼 수 없어요.'), findsOneWidget);
  });

  testWidgets('a missing related note is announced, no note means no card', (
    tester,
  ) async {
    await tester.pumpAtSize(
      app(
        reviews: FakeReviewRepository([
          sampleReview(
            questionId: 'question-1',
            topic: 'Dictionary',
            prompt: 'p',
            noteId: 'note-gone',
          ),
        ]),
      ),
      TestScreenSizes.tablet,
    );
    expect(find.text('관련 노트를 더 이상 볼 수 없어요.'), findsOneWidget);
    expect(find.text('노트에서 확인 →'), findsNothing);
    expect(find.text('복습'), findsOneWidget);

    await tester.pumpAtSize(
      app(
        reviews: FakeReviewRepository([
          sampleReview(
            questionId: 'question-1',
            topic: 'Dictionary',
            prompt: 'p',
            noteId: null,
          ),
        ]),
      ),
      TestScreenSizes.tablet,
    );
    expect(find.text('관련 학습 내용'), findsNothing);
  });

  testWidgets('an unknown review id shows a not-found notice', (tester) async {
    await tester.pumpAtSize(app(id: 'nope'), TestScreenSizes.phone);
    expect(find.text('복습 항목을 찾을 수 없어요.'), findsOneWidget);
    expect(find.text('다시 풀어보기'), findsNothing);
  });

  testWidgets('the overflow menu marks the item as reviewed', (tester) async {
    final reviews = FakeReviewRepository(sampleReviews());
    await tester.pumpAtSize(app(reviews: reviews), TestScreenSizes.desktop);
    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 확인함으로 표시'));
    await tester.pumpAndSettle();
    expect(reviews.items[reviewId]!.status, ReviewStatus.reviewed);
    expect(find.text('다시 확인함으로 표시했어요.'), findsOneWidget);
  });
}

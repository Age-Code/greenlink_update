import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/format/relative_time.dart';
import 'package:tutoring/features/classes/presentation/controllers/student_progress.dart';
import 'package:tutoring/features/classes/presentation/screens/class_home_screen.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

void main() {
  group('student progress helpers', () {
    final quizzes = [sampleQuiz(id: 'quiz-1'), sampleQuiz(id: 'quiz-2')];

    test('finished quizzes drive the progress and the pending count', () {
      expect(quizCompletionProgress(quizzes, const []), 0);
      expect(unsolvedQuizzes(quizzes, const []).length, 2);

      final attempts = [sampleAttempt(id: 'a1', quizId: 'quiz-1')];
      expect(quizCompletionProgress(quizzes, attempts), 0.5);
      expect(
        unsolvedQuizzes(quizzes, attempts).map((quiz) => quiz.id),
        ['quiz-2'],
      );
      expect(quizCompletionProgress(const [], attempts), 0);
    });

    test('an attempt made before the quiz changed size no longer counts', () {
      final resized = sampleQuiz(id: 'quiz-1').copyWith(questionCount: 6);
      final attempts = [sampleAttempt(id: 'a1', quizId: 'quiz-1')];
      expect(attemptsForQuiz(resized, attempts), isEmpty);
    });

    test('reading time and latest activity', () {
      expect(estimatedReadingMinutes(0), 5);
      expect(estimatedReadingMinutes(10), 15);
      expect(latestStudyTime(const []), isNull);
      final later = sampleAttempt(id: 'a2', quizId: 'quiz-1');
      expect(latestStudyTime([later]), later.completedAt);
    });

    test('relative time labels', () {
      final now = DateTime(2026, 11, 8, 12);
      expect(relativeTimeLabel(now, now: now), '방금');
      expect(relativeTimeLabel(now.subtract(const Duration(minutes: 5)), now: now), '5분 전');
      expect(relativeTimeLabel(now.subtract(const Duration(hours: 2)), now: now), '2시간 전');
      expect(relativeTimeLabel(now.subtract(const Duration(hours: 30)), now: now), '어제');
      expect(relativeTimeLabel(now.subtract(const Duration(days: 3)), now: now), '3일 전');
      expect(relativeTimeLabel(DateTime(2026, 10, 1), now: now), '10/1');
    });
  });

  Widget app({List<dynamic>? attempts, List<dynamic>? quizzes}) =>
      buildSignedInApp(
        home: const ClassHomeScreen(classId: 'class-1'),
        user: tuteeUser,
        attempts: attempts?.cast() ?? const [],
        quizzes: quizzes?.cast(),
        reviews: FakeReviewRepository(sampleReviews()),
      );

  testAtScreenSizes(
    'class home shows the latest note, live counts and both columns',
    app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('Week 03'), findsWidgets);
      expect(find.text('Week 3 · 딕셔너리와 집합 자료형 정리'), findsWidgets);
      expect(find.text('이어서 보기'), findsOneWidget);
      expect(find.text('예상 소요 시간 약 5분'), findsOneWidget);
      expect(find.text('진행률 0%'), findsOneWidget);
      expect(find.text('아직 학습 기록이 없어요'), findsOneWidget);
      expect(find.text('풀지 않은 퀴즈가 1개 있어요.'), findsOneWidget);
      expect(find.text('다시 확인할 문제가 2개 있어요.'), findsOneWidget);
      expect(find.text('전체 보기'), findsOneWidget);
      expect(find.text('Week 2 · 딕셔너리와 집합 자료형 정리'), findsOneWidget);

      final notesTop = tester.getTopLeft(find.text('최근 노트'));
      final tasksTop = tester.getTopLeft(find.text('활동 과제'));
      if (size.width < 600) {
        expect(tasksTop.dy, greaterThan(notesTop.dy));
      } else {
        expect(tasksTop.dy, notesTop.dy);
        expect(tasksTop.dx, greaterThan(notesTop.dx));
      }
    },
  );

  testWidgets('a finished quiz fills the progress and clears the quiz task', (
    tester,
  ) async {
    await tester.pumpAtSize(
      app(attempts: [sampleAttempt(id: 'attempt-1', quizId: 'quiz-1')]),
      TestScreenSizes.tablet,
    );
    expect(find.text('진행률 100%'), findsOneWidget);
    expect(find.text('모든 퀴즈를 풀었어요.'), findsOneWidget);
    expect(find.textContaining('최근 학습 · '), findsOneWidget);
    expect(find.text('학습 중인 세션'), findsOneWidget);
  });

  testWidgets('no published quiz is said plainly', (tester) async {
    await tester.pumpAtSize(
      app(quizzes: [sampleQuiz(id: 'quiz-2', status: QuizStatus.draft)]),
      TestScreenSizes.tablet,
    );
    expect(find.text('게시된 퀴즈 없음'), findsOneWidget);
    expect(find.text('아직 게시된 퀴즈가 없어요.'), findsOneWidget);
  });

  testWidgets('the drawer shows badges and opens the class info sheet', (
    tester,
  ) async {
    await tester.pumpAtSize(app(), TestScreenSizes.phone);
    await tester.tap(find.byTooltip('클래스 메뉴'));
    await tester.pumpAndSettle();
    expect(find.text('Tutor · 김튜터'), findsWidgets);
    expect(find.text('진행 중'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('1건 대기'), findsOneWidget);

    await tester.tap(find.text('클래스 정보'));
    await tester.pumpAndSettle();
    expect(find.text('ABCD1234'), findsOneWidget);
    expect(find.text('5명'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop: the menu button toggles the sidebar, which holds the '
      'info entry', (tester) async {
    await tester.pumpAtSize(app(), TestScreenSizes.desktop);
    expect(find.byTooltip('클래스 메뉴'), findsNothing);
    expect(find.text('클래스 정보'), findsNothing);

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    expect(find.text('클래스 정보'), findsOneWidget);
    expect(find.text('내 클래스 목록'), findsOneWidget);

    await tester.tap(find.byTooltip('클래스 정보'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('ABCD1234'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('메뉴 닫기'));
    await tester.pumpAndSettle();
    expect(find.text('클래스 정보'), findsNothing);
    expect(find.byTooltip('메뉴 열기'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/reviews/presentation/screens/review_session_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

const _q1 = 'class-1_quiz-1_question-1';
const _q2 = 'class-1_quiz-1_question-2';

void main() {
  Widget app({List<String> ids = const [_q1, _q2]}) => buildSignedInApp(
    home: ReviewSessionScreen(classId: 'class-1', reviewIds: ids),
    user: tuteeUser,
    reviews: FakeReviewRepository(sampleReviews()),
  );

  Future<void> check(WidgetTester tester, String option) async {
    await tester.tap(find.text(option));
    await tester.pump();
    await tester.tap(find.text('정답 확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final size in TestScreenSizes.all) {
    testWidgets('full retry flow fits at ${size.width.toInt()}', (
      tester,
    ) async {
      await tester.pumpAtSize(app(), size);
      expect(find.text('복습'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('QUESTION 1'), findsOneWidget);
      expect(find.text('다시 풀기 · Dictionary'), findsOneWidget);

      await check(tester, 'data.get(key)');
      expect(find.text('이제 이해했어요!'), findsOneWidget);
      expect(find.text('기억 복구됨'), findsOneWidget);
      expect(find.textContaining("'다시 확인함'으로 바꿨어요"), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('다음 복습'));
      await tester.pump();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('다시 풀기 · List & Tuple'), findsOneWidget);

      await check(tester, 'data[key]');
      expect(find.text('한 번 더 확인해볼까요?'), findsOneWidget);
      expect(find.textContaining('복습 목록에 그대로 남아요'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('결과 보기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('복습을 마쳤어요.'), findsOneWidget);
      expect(find.text('2문제 중 1문제를 다시 확인했어요.'), findsOneWidget);
      expect(find.text('1문제는 복습 목록에 남아 있어요.'), findsOneWidget);
      expect(find.text('복습 목록으로'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('number keys and Enter drive the session on desktop', (
    tester,
  ) async {
    await tester.pumpAtSize(app(), TestScreenSizes.desktop);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('이제 이해했어요!'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('leaving mid-session asks for confirmation', (tester) async {
    await tester.pumpAtSize(app(), TestScreenSizes.phone);
    await check(tester, 'data.get(key)');
    await tester.tap(find.byTooltip('돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('복습을 그만둘까요?'), findsOneWidget);
    await tester.tap(find.text('계속 풀기'));
    await tester.pumpAndSettle();
    expect(find.text('이제 이해했어요!'), findsOneWidget);
  });

  testWidgets('no ids shows an empty notice', (tester) async {
    await tester.pumpAtSize(app(ids: const []), TestScreenSizes.phone);
    expect(find.text('복습할 문제가 없어요.'), findsOneWidget);
    expect(find.text('정답 확인'), findsNothing);
  });
}

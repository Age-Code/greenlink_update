import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/quizzes/presentation/screens/quiz_solve_screen.dart';
import 'package:tutoring/features/quizzes/presentation/widgets/explanation_text.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

void main() {
  Widget app({FakeReviewRepository? reviews}) => buildSignedInApp(
    home: const QuizSolveScreen(classId: 'class-1', quizId: 'quiz-1'),
    user: tuteeUser,
    reviews: reviews,
  );

  for (final size in TestScreenSizes.all) {
    testWidgets(
      'wrong answer shows feedback and fits at ${size.width.toInt()}',
      (tester) async {
        final reviews = FakeReviewRepository();
        await tester.pumpAtSize(app(reviews: reviews), size);
        expect(find.text('QUESTION 1'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);

        await tester.tap(find.text('data[key]'));
        await tester.pump();
        await tester.tap(find.text('정답 확인'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('한 번 더 확인해볼까요?'), findsOneWidget);
        expect(find.text('내 답'), findsOneWidget);
        expect(find.text('정답'), findsOneWidget);
        expect(find.text('복습 목록에 자동으로 추가했어요.'), findsOneWidget);
        expect(find.byType(ExplanationCodeCard), findsOneWidget);
        expect(find.textContaining('관련 학습: Week 3'), findsOneWidget);
        expect(find.text('다음 문제'), findsOneWidget);
        expect(reviews.items, hasLength(1));
        if (size.width < 600) {
          expect(find.text('오답 노트'), findsNothing);
          expect(find.byTooltip('오답 노트'), findsOneWidget);
        } else {
          expect(find.text('오답 노트'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('number keys select an option and Enter checks, then advances', (
    tester,
  ) async {
    await tester.pumpAtSize(app(), TestScreenSizes.desktop);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('잘했어요!'), findsOneWidget);
    expect(find.text('복습 목록에 자동으로 추가했어요.'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('QUESTION 2'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('parseExplanation splits paragraphs and fenced code', () {
    final segments = parseExplanation(
      '앞 문장 `a` 입니다.\n```python\nx = 1\n```\n뒤 문장',
    );
    expect(segments, hasLength(3));
    expect((segments[0] as ExplanationParagraph).text, '앞 문장 `a` 입니다.');
    final code = segments[1] as ExplanationCode;
    expect(code.language, 'python');
    expect(code.code, 'x = 1');
    expect((segments[2] as ExplanationParagraph).text, '뒤 문장');
    expect(parseExplanation('그냥 글'), hasLength(1));
  });
}

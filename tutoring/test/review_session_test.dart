import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

import 'helpers/fake_repositories.dart';

const _q1 = 'class-1_quiz-1_question-1';
const _q2 = 'class-1_quiz-1_question-2';

void main() {
  QuizSessionController build({
    required FakeReviewRepository reviews,
    List<String> ids = const [_q1, _q2],
    QuizStatus quizStatus = QuizStatus.published,
  }) => QuizSessionController.review(
    quizRepository: FakeQuizRepository(
      [sampleQuiz(id: 'quiz-1', status: quizStatus)],
      questions: sampleQuestions(),
    ),
    reviewRepository: reviews,
    args: (userId: 'tutee-1', classId: 'class-1', reviewIds: ids.join(',')),
  );

  test('review retry walks the ids in order, marks hits reviewed and counts '
      'misses up', () async {
    final reviews = FakeReviewRepository(sampleReviews());
    final controller = build(reviews: reviews);
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    expect(controller.state.quiz, isNull);
    expect(
      controller.state.questions.map((q) => q.id),
      ['question-1', 'question-2'],
    );
    expect(controller.state.topicsByQuestionId['question-1'], 'Dictionary');
    expect(controller.state.topicsByQuestionId['question-2'], 'List & Tuple');

    controller.selectAnswer(1);
    await controller.checkAnswer();
    expect(controller.state.isReviewSaved, isTrue);
    expect(reviews.items[_q1]!.status, ReviewStatus.reviewed);
    expect(reviews.items[_q1]!.wrongCount, 1);
    expect(controller.state.isComplete, isFalse);

    await controller.next();
    expect(controller.state.currentQuestionIndex, 1);
    controller.selectAnswer(0);
    await controller.checkAnswer();
    expect(controller.state.isReviewSaved, isTrue);
    expect(reviews.items[_q2]!.status, ReviewStatus.needsReview);
    expect(reviews.items[_q2]!.wrongCount, 2);
    expect(reviews.items[_q2]!.lastSelectedOptionIndex, 0);

    await controller.next();
    expect(controller.state.isComplete, isTrue);
    expect(controller.state.attemptId, isNull);
    expect(controller.state.correctCount, 1);
  });

  test('a reviewed item answered wrong again goes back to needsReview',
      () async {
    final reviews = FakeReviewRepository(sampleReviews());
    const reviewedId = 'class-1_quiz-1_question-3';
    expect(reviews.items[reviewedId]!.status, ReviewStatus.reviewed);
    final controller = build(reviews: reviews, ids: const [reviewedId]);
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    controller.selectAnswer(3);
    await controller.checkAnswer();
    expect(reviews.items[reviewedId]!.status, ReviewStatus.needsReview);
    expect(reviews.items[reviewedId]!.wrongCount, 2);
  });

  test('ids without a live question are skipped', () async {
    final reviews = FakeReviewRepository([
      ...sampleReviews(),
      sampleReview(questionId: 'question-9', topic: 'Gone', prompt: 'gone'),
    ]);
    final controller = build(
      reviews: reviews,
      ids: const [_q1, 'class-1_quiz-1_question-9', 'not-an-item'],
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);
    expect(controller.state.questions.map((q) => q.id), ['question-1']);
  });

  test('an unpublished quiz leaves nothing to review', () async {
    final controller = build(
      reviews: FakeReviewRepository(sampleReviews()),
      quizStatus: QuizStatus.draft,
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);
    expect(controller.state.questions, isEmpty);
    expect(controller.state.errorMessage, '복습할 문제를 불러오지 못했어요.');
  });

  test('review session ids round-trip through the route', () {
    final path = AppRoutes.reviewSession('class-1', ids: const [_q1, _q2]);
    final ids = AppRoutes.parseReviewSessionIds(
      Uri.parse(path).queryParameters['ids'],
    );
    expect(ids, [_q1, _q2]);
    expect(AppRoutes.parseReviewSessionIds(null), isEmpty);
    expect(AppRoutes.parseReviewSessionIds(' , '), isEmpty);
  });
}

Future<void> _waitForLoad(QuizSessionController controller) async {
  for (var index = 0; index < 50 && controller.state.isLoading; index++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(controller.state.isLoading, isFalse);
}

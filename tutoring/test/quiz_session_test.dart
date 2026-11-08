import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/reviews/domain/entities/review_status.dart';

import 'helpers/fake_repositories.dart';

void main() {
  test('quiz session checks locally and saves once after final question', () async {
    final quizRepository = _FakeQuizRepository();
    final attemptRepository = _FakeAttemptRepository();
    final controller = QuizSessionController(
      quizRepository: quizRepository,
      attemptRepository: attemptRepository,
      reviewRepository: FakeReviewRepository(),
      args: (
        userId: 'tutee-1',
        classId: 'class-1',
        quizId: 'quiz-1',
        questionId: null,
        noteId: null,
      ),
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    for (var index = 0; index < 3; index++) {
      controller.selectAnswer(1);
      await controller.checkAnswer();
      expect(controller.state.isAnswerChecked, isTrue);
      expect(attemptRepository.attempts, isEmpty);
      await controller.next();
    }

    expect(controller.state.isComplete, isTrue);
    expect(controller.state.correctCount, 3);
    expect(attemptRepository.attempts, hasLength(1));
    expect(attemptRepository.attempts.single.totalQuestions, 3);
  });

  test('Quick Check saves an independent one-question attempt immediately', () async {
    final quizRepository = _FakeQuizRepository();
    final attemptRepository = _FakeAttemptRepository();
    final controller = QuizSessionController(
      quizRepository: quizRepository,
      attemptRepository: attemptRepository,
      reviewRepository: FakeReviewRepository(),
      args: (
        userId: 'tutee-1',
        classId: 'class-1',
        quizId: 'quiz-1',
        questionId: 'question-2',
        noteId: 'note-1',
      ),
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    controller.selectAnswer(0);
    await controller.checkAnswer();

    expect(controller.state.isComplete, isTrue);
    expect(controller.state.correctCount, 0);
    expect(attemptRepository.attempts.single.noteId, 'note-1');
    expect(attemptRepository.attempts.single.answers.single.questionId,
        'question-2');
  });

  test('wrong answers are recorded as review items, correct ones are not',
      () async {
    final reviewRepository = FakeReviewRepository();
    final controller = QuizSessionController(
      quizRepository: _FakeQuizRepository(),
      attemptRepository: _FakeAttemptRepository(),
      reviewRepository: reviewRepository,
      args: (
        userId: 'tutee-1',
        classId: 'class-1',
        quizId: 'quiz-1',
        questionId: null,
        noteId: null,
      ),
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    controller.selectAnswer(0);
    await controller.checkAnswer();
    expect(controller.state.isReviewSaved, isTrue);
    final review = reviewRepository.items.values.single;
    expect(review.id, 'class-1_quiz-1_question-1');
    expect(review.userId, 'tutee-1');
    expect(review.wrongCount, 1);
    expect(review.lastSelectedOptionIndex, 0);
    expect(review.status, ReviewStatus.needsReview);
    expect(review.topic, 'Dictionary Quiz');
    expect(review.prompt, '문제 1');
    expect(review.noteId, 'note-1');

    await controller.next();
    expect(controller.state.isReviewSaved, isFalse);
    controller.selectAnswer(1);
    await controller.checkAnswer();
    expect(controller.state.isReviewSaved, isFalse);
    expect(reviewRepository.items, hasLength(1));
  });

  test('a failed review write is reported but does not block the quiz',
      () async {
    final reviewRepository = FakeReviewRepository()..failWrites = true;
    final attemptRepository = _FakeAttemptRepository();
    final controller = QuizSessionController(
      quizRepository: _FakeQuizRepository(),
      attemptRepository: attemptRepository,
      reviewRepository: reviewRepository,
      args: (
        userId: 'tutee-1',
        classId: 'class-1',
        quizId: 'quiz-1',
        questionId: null,
        noteId: null,
      ),
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    controller.selectAnswer(0);
    await controller.checkAnswer();
    expect(controller.state.isAnswerChecked, isTrue);
    expect(controller.state.isReviewSaved, isFalse);
    expect(controller.state.isReviewSaveFailed, isTrue);
    expect(reviewRepository.items, isEmpty);

    await controller.next();
    expect(controller.state.isReviewSaveFailed, isFalse);
    controller.selectAnswer(1);
    await controller.checkAnswer();
    await controller.next();
    controller.selectAnswer(1);
    await controller.checkAnswer();
    await controller.next();
    expect(controller.state.isComplete, isTrue);
    expect(attemptRepository.attempts, hasLength(1));
  });

  test('a Quick Check miss is recorded with the question and host note',
      () async {
    final reviewRepository = FakeReviewRepository();
    final controller = QuizSessionController(
      quizRepository: _FakeQuizRepository(),
      attemptRepository: _FakeAttemptRepository(),
      reviewRepository: reviewRepository,
      args: (
        userId: 'tutee-1',
        classId: 'class-1',
        quizId: 'quiz-1',
        questionId: 'question-3',
        noteId: 'note-1',
      ),
    );
    addTearDown(controller.dispose);
    await _waitForLoad(controller);

    controller.selectAnswer(2);
    await controller.checkAnswer();
    expect(controller.state.isComplete, isTrue);
    expect(controller.state.isReviewSaved, isTrue);
    final review = reviewRepository.items.values.single;
    expect(review.questionId, 'question-3');
    expect(review.noteId, 'note-1');
    expect(review.lastSelectedOptionIndex, 2);
  });
}

Future<void> _waitForLoad(QuizSessionController controller) async {
  await _settle(controller);
}

Future<void> _settle(QuizSessionController controller) async {
  for (var index = 0; index < 20 && controller.state.isLoading; index++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(controller.state.isLoading, isFalse);
}

class _FakeQuizRepository implements QuizRepository {
  final quiz = StudyQuiz(
    id: 'quiz-1',
    classId: 'class-1',
    title: 'Dictionary Quiz',
    description: '',
    createdBy: 'tutor-1',
    status: QuizStatus.published,
    questionCount: 3,
    createdAt: DateTime(2026, 11, 5),
    updatedAt: DateTime(2026, 11, 5),
    publishedAt: DateTime(2026, 11, 5),
    noteId: 'note-1',
  );

  late final questions = [
    for (var index = 0; index < 3; index++)
      QuizQuestion(
        id: 'question-${index + 1}',
        quizId: 'quiz-1',
        type: QuizQuestionType.multipleChoice,
        prompt: '문제 ${index + 1}',
        options: const ['A', 'B', 'C', 'D'],
        correctOptionIndex: 1,
        explanation: 'B가 정답입니다.',
        order: index,
        relatedNoteId: 'note-1',
        relatedBlockId: null,
      ),
  ];

  @override
  Future<StudyQuiz?> getQuiz(String classId, String quizId) async => quiz;

  @override
  Future<List<QuizQuestion>> getQuestions(
    String classId,
    String quizId,
  ) async => questions;

  @override
  Future<String> saveQuiz({
    required StudyQuiz quiz,
    required List<QuizQuestion> questions,
  }) async => quiz.id;

  @override
  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) async {}

  @override
  Future<void> deleteQuiz(String classId, String quizId) async {}

  @override
  Stream<List<StudyQuiz>> watchAllQuizzes(String classId) =>
      Stream.value([quiz]);

  @override
  Stream<List<StudyQuiz>> watchPublishedQuizzes(String classId) =>
      Stream.value([quiz]);
}

class _FakeAttemptRepository implements QuizAttemptRepository {
  @override
  Future<void> deleteAllForUser(String userId) async {}

  final List<QuizAttempt> attempts = [];

  @override
  Future<String> createAttempt(QuizAttempt attempt) async {
    final id = 'attempt-${attempts.length + 1}';
    attempts.add(
      QuizAttempt(
        id: id,
        userId: attempt.userId,
        classId: attempt.classId,
        quizId: attempt.quizId,
        noteId: attempt.noteId,
        startedAt: attempt.startedAt,
        completedAt: attempt.completedAt,
        totalQuestions: attempt.totalQuestions,
        correctCount: attempt.correctCount,
        answers: attempt.answers,
      ),
    );
    return id;
  }

  @override
  Stream<List<QuizAttempt>> watchAttempts(String userId) =>
      Stream.value(attempts);

  @override
  Stream<List<QuizAttempt>> watchClassAttempts(String classId) => Stream.value(
        attempts.where((attempt) => attempt.classId == classId).toList(),
      );
}

import 'package:tutoring/features/quizzes/domain/entities/quiz_answer.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';

/// Where a session's questions come from and how answers are persisted.
///
/// `QuizSessionController` owns the shared flow (select, check, next,
/// complete); a source only loads content and writes results, so the quiz
/// run, the note Quick Check and the review retry share one state machine.
abstract interface class QuizSessionSource {
  String get loadErrorMessage;
  String get completeErrorMessage;

  /// Quick Check: a single question whose result is stored right after it is
  /// checked instead of after a "next" tap.
  bool get completesAfterFirstAnswer;

  Future<QuizSessionContent> load();

  /// Persists one checked answer. Returns true when something was written.
  Future<bool> recordAnswer(QuizQuestion question, QuizAnswer answer);

  /// Runs once after the last answer. Returns the stored attempt id, if any.
  Future<String?> complete(QuizSessionState state);
}

class QuizSessionContent {
  const QuizSessionContent({
    required this.quiz,
    required this.questions,
    this.topicsByQuestionId = const {},
  });

  final StudyQuiz? quiz;
  final List<QuizQuestion> questions;

  /// Label shown next to a question (review retry: the item's topic).
  final Map<String, String> topicsByQuestionId;
}

/// A published quiz (or one Quick Check question of it). Misses go to the
/// review list; the whole run is stored as one immutable attempt.
class QuizRunSource implements QuizSessionSource {
  QuizRunSource({
    required this.quizRepository,
    required this.attemptRepository,
    required this.reviewRepository,
    required this.args,
  });

  final QuizRepository quizRepository;
  final QuizAttemptRepository attemptRepository;
  final ReviewRepository reviewRepository;
  final QuizSessionArgs args;

  StudyQuiz? _quiz;

  @override
  String get loadErrorMessage => '퀴즈를 불러오지 못했어요.';

  @override
  String get completeErrorMessage => '풀이 결과를 저장하지 못했어요. 다시 시도해주세요.';

  @override
  bool get completesAfterFirstAnswer => args.questionId != null;

  @override
  Future<QuizSessionContent> load() async {
    final quiz = await quizRepository.getQuiz(args.classId, args.quizId);
    final allQuestions = await quizRepository.getQuestions(
      args.classId,
      args.quizId,
    );
    if (quiz == null || quiz.status != QuizStatus.published) {
      throw StateError('published quiz not found');
    }
    final questions =
        args.questionId == null
            ? allQuestions
            : allQuestions
                .where((question) => question.id == args.questionId)
                .toList(growable: false);
    if (questions.isEmpty) throw StateError('question not found');
    if (questions.any((question) => !question.isValid)) {
      throw StateError('invalid published question');
    }
    _quiz = quiz;
    return QuizSessionContent(quiz: quiz, questions: questions);
  }

  @override
  Future<bool> recordAnswer(QuizQuestion question, QuizAnswer answer) async {
    final quiz = _quiz;
    if (answer.isCorrect || quiz == null) return false;
    final relatedNoteId = question.relatedNoteId;
    final hasRelatedNote = relatedNoteId != null && relatedNoteId.isNotEmpty;
    await reviewRepository.recordWrongAnswer(
      userId: args.userId,
      classId: args.classId,
      quizId: args.quizId,
      questionId: question.id,
      noteId: hasRelatedNote ? relatedNoteId : args.noteId ?? quiz.noteId,
      blockId: hasRelatedNote ? question.relatedBlockId : null,
      topic: quiz.title,
      prompt: question.prompt,
      selectedOptionIndex: answer.selectedAnswer,
    );
    return true;
  }

  @override
  Future<String?> complete(QuizSessionState state) {
    final quiz = _quiz;
    if (quiz == null) throw StateError('quiz not loaded');
    return attemptRepository.createAttempt(
      QuizAttempt(
        id: '',
        userId: args.userId,
        classId: args.classId,
        quizId: args.quizId,
        noteId: args.noteId ?? quiz.noteId,
        startedAt: state.startedAt,
        completedAt: DateTime.now(),
        totalQuestions: state.questions.length,
        correctCount: state.correctCount,
        answers: state.answers,
      ),
    );
  }
}

/// Review retry over the learner's own review items (12_Review_Retry).
///
/// Questions are read fresh from their quizzes in the order of [args]; items
/// whose quiz was deleted or unpublished are skipped. A correct answer marks
/// the item reviewed, a miss counts up and keeps it pending. No attempt is
/// stored, so retries never touch the tutor's quiz statistics.
class ReviewRunSource implements QuizSessionSource {
  ReviewRunSource({
    required this.quizRepository,
    required this.reviewRepository,
    required this.args,
  });

  final QuizRepository quizRepository;
  final ReviewRepository reviewRepository;
  final ReviewSessionArgs args;

  final _itemsByQuestionId = <String, ReviewItem>{};
  final _quizzesById = <String, StudyQuiz>{};

  @override
  String get loadErrorMessage => '복습할 문제를 불러오지 못했어요.';

  @override
  String get completeErrorMessage => '복습 결과를 정리하지 못했어요.';

  @override
  bool get completesAfterFirstAnswer => false;

  @override
  Future<QuizSessionContent> load() async {
    final ids = args.reviewIds
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty);
    final items = <ReviewItem>[];
    for (final id in ids) {
      final item = await reviewRepository.getReview(
        userId: args.userId,
        reviewId: id,
      );
      if (item != null && item.classId == args.classId) items.add(item);
    }

    final questionsByQuiz = <String, Map<String, QuizQuestion>>{};
    for (final quizId in items.map((item) => item.quizId).toSet()) {
      try {
        final quiz = await quizRepository.getQuiz(args.classId, quizId);
        if (quiz == null || quiz.status != QuizStatus.published) continue;
        final questions = await quizRepository.getQuestions(
          args.classId,
          quizId,
        );
        _quizzesById[quizId] = quiz;
        questionsByQuiz[quizId] = {
          for (final question in questions) question.id: question,
        };
      } catch (_) {
        // Unreadable quiz: its items are skipped below.
      }
    }

    final questions = <QuizQuestion>[];
    final topics = <String, String>{};
    for (final item in items) {
      final question = questionsByQuiz[item.quizId]?[item.questionId];
      if (question == null || !question.isValid) continue;
      if (_itemsByQuestionId.containsKey(question.id)) continue;
      _itemsByQuestionId[question.id] = item;
      topics[question.id] = item.topic;
      questions.add(question);
    }
    if (questions.isEmpty) throw StateError('no review questions available');
    return QuizSessionContent(
      quiz: null,
      questions: questions,
      topicsByQuestionId: topics,
    );
  }

  @override
  Future<bool> recordAnswer(QuizQuestion question, QuizAnswer answer) async {
    final item = _itemsByQuestionId[question.id];
    if (item == null) return false;
    if (answer.isCorrect) {
      await reviewRepository.markReviewed(
        userId: args.userId,
        reviewId: item.id,
      );
      return true;
    }
    final relatedNoteId = question.relatedNoteId;
    final hasRelatedNote = relatedNoteId != null && relatedNoteId.isNotEmpty;
    await reviewRepository.recordWrongAnswer(
      userId: args.userId,
      classId: item.classId,
      quizId: item.quizId,
      questionId: question.id,
      noteId: hasRelatedNote ? relatedNoteId : item.noteId,
      blockId: hasRelatedNote ? question.relatedBlockId : item.blockId,
      topic: _quizzesById[item.quizId]?.title ?? item.topic,
      prompt: question.prompt,
      selectedOptionIndex: answer.selectedAnswer,
    );
    return true;
  }

  @override
  Future<String?> complete(QuizSessionState state) async => null;
}

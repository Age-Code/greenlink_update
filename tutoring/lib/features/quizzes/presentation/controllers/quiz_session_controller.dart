import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_answer.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_session_source.dart';
import 'package:tutoring/features/reviews/data/review_data_providers.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';

typedef QuizSessionArgs = ({
  String userId,
  String classId,
  String quizId,
  String? questionId,
  String? noteId,
});

/// [reviewIds] is comma-joined so the record compares by value.
typedef ReviewSessionArgs = ({
  String userId,
  String classId,
  String reviewIds,
});

final quizSessionControllerProvider = StateNotifierProvider.autoDispose.family<
    QuizSessionController, QuizSessionState, QuizSessionArgs>((ref, args) {
  return QuizSessionController(
    quizRepository: ref.watch(quizRepositoryProvider),
    attemptRepository: ref.watch(quizAttemptRepositoryProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    args: args,
  );
});

final reviewSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizSessionController, QuizSessionState, ReviewSessionArgs>((
  ref,
  args,
) {
  return QuizSessionController.review(
    quizRepository: ref.watch(quizRepositoryProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    args: args,
  );
});

class QuizSessionState {
  const QuizSessionState({
    required this.quiz,
    required this.questions,
    required this.topicsByQuestionId,
    required this.currentQuestionIndex,
    required this.selectedAnswer,
    required this.isAnswerChecked,
    required this.answers,
    required this.startedAt,
    required this.isLoading,
    required this.isSubmitting,
    required this.completed,
    required this.attemptId,
    required this.isReviewSaved,
    required this.isReviewSaveFailed,
    required this.errorMessage,
  });

  factory QuizSessionState.initial() => QuizSessionState(
    quiz: null,
    questions: const [],
    topicsByQuestionId: const {},
    currentQuestionIndex: 0,
    selectedAnswer: null,
    isAnswerChecked: false,
    answers: const [],
    startedAt: DateTime.now(),
    isLoading: true,
    isSubmitting: false,
    completed: false,
    attemptId: null,
    isReviewSaved: false,
    isReviewSaveFailed: false,
    errorMessage: null,
  );

  /// Null for a review retry, which mixes questions of several quizzes.
  final StudyQuiz? quiz;
  final List<QuizQuestion> questions;
  final Map<String, String> topicsByQuestionId;
  final int currentQuestionIndex;
  final int? selectedAnswer;
  final bool isAnswerChecked;
  final List<QuizAnswer> answers;
  final DateTime startedAt;
  final bool isLoading;
  final bool isSubmitting;

  /// True once the last answer was handled by the session source.
  final bool completed;

  /// Stored attempt id for a quiz run; null for a review retry.
  final String? attemptId;

  /// True once the current answer's review bookkeeping was written.
  final bool isReviewSaved;

  /// True when that bookkeeping failed (rules, network).
  final bool isReviewSaveFailed;
  final String? errorMessage;

  QuizQuestion? get currentQuestion =>
      currentQuestionIndex >= 0 && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  bool get isComplete => completed;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;

  QuizAnswer? get currentAnswer {
    final question = currentQuestion;
    if (question == null) return null;
    for (final answer in answers.reversed) {
      if (answer.questionId == question.id) return answer;
    }
    return null;
  }

  QuizSessionState copyWith({
    StudyQuiz? quiz,
    List<QuizQuestion>? questions,
    Map<String, String>? topicsByQuestionId,
    int? currentQuestionIndex,
    int? selectedAnswer,
    bool? isAnswerChecked,
    List<QuizAnswer>? answers,
    DateTime? startedAt,
    bool? isLoading,
    bool? isSubmitting,
    bool? completed,
    String? attemptId,
    bool? isReviewSaved,
    bool? isReviewSaveFailed,
    String? errorMessage,
    bool clearSelectedAnswer = false,
    bool clearError = false,
  }) => QuizSessionState(
    quiz: quiz ?? this.quiz,
    questions: questions ?? this.questions,
    topicsByQuestionId: topicsByQuestionId ?? this.topicsByQuestionId,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    selectedAnswer:
        clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
    isAnswerChecked: isAnswerChecked ?? this.isAnswerChecked,
    answers: answers ?? this.answers,
    startedAt: startedAt ?? this.startedAt,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    completed: completed ?? this.completed,
    attemptId: attemptId ?? this.attemptId,
    isReviewSaved: isReviewSaved ?? this.isReviewSaved,
    isReviewSaveFailed: isReviewSaveFailed ?? this.isReviewSaveFailed,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

/// One question-at-a-time flow shared by quiz runs, Quick Checks and review
/// retries. Grading is local (`selectedAnswer == correctOptionIndex`); what
/// gets written is decided by the [source].
class QuizSessionController extends StateNotifier<QuizSessionState> {
  /// A published quiz, or one Quick Check question of it.
  QuizSessionController({
    required QuizRepository quizRepository,
    required QuizAttemptRepository attemptRepository,
    required ReviewRepository reviewRepository,
    required QuizSessionArgs args,
  }) : this.withSource(
         QuizRunSource(
           quizRepository: quizRepository,
           attemptRepository: attemptRepository,
           reviewRepository: reviewRepository,
           args: args,
         ),
       );

  /// Review retry over the learner's own review items.
  QuizSessionController.review({
    required QuizRepository quizRepository,
    required ReviewRepository reviewRepository,
    required ReviewSessionArgs args,
  }) : this.withSource(
         ReviewRunSource(
           quizRepository: quizRepository,
           reviewRepository: reviewRepository,
           args: args,
         ),
       );

  QuizSessionController.withSource(this.source)
    : super(QuizSessionState.initial()) {
    _load();
  }

  final QuizSessionSource source;

  Future<void> _load() async {
    try {
      final content = await source.load();
      if (!mounted) return;
      state = state.copyWith(
        quiz: content.quiz,
        questions: content.questions,
        topicsByQuestionId: content.topicsByQuestionId,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: source.loadErrorMessage,
      );
    }
  }

  void selectAnswer(int index) {
    if (state.isAnswerChecked || state.isSubmitting || state.isComplete) return;
    final question = state.currentQuestion;
    if (question == null || index < 0 || index >= question.options.length) {
      return;
    }
    state = state.copyWith(selectedAnswer: index, clearError: true);
  }

  Future<void> checkAnswer() async {
    if (state.isAnswerChecked || state.selectedAnswer == null) return;
    final question = state.currentQuestion;
    if (question == null) return;
    final answer = QuizAnswer(
      questionId: question.id,
      selectedAnswer: state.selectedAnswer!,
      isCorrect: state.selectedAnswer == question.correctOptionIndex,
      answeredAt: DateTime.now(),
    );
    state = state.copyWith(
      isAnswerChecked: true,
      answers: [...state.answers, answer],
      isReviewSaved: false,
      isReviewSaveFailed: false,
      clearError: true,
    );
    await _recordAnswer(question, answer);
    if (source.completesAfterFirstAnswer) await _complete();
  }

  Future<void> next() async {
    if (!state.isAnswerChecked || state.isSubmitting || state.isComplete) return;
    if (state.currentQuestionIndex >= state.questions.length - 1) {
      await _complete();
      return;
    }
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
      isAnswerChecked: false,
      isReviewSaved: false,
      isReviewSaveFailed: false,
      clearSelectedAnswer: true,
      clearError: true,
    );
  }

  /// Review bookkeeping never blocks the session; a failure is only surfaced
  /// as a line in the feedback card.
  Future<void> _recordAnswer(QuizQuestion question, QuizAnswer answer) async {
    final bool saved;
    try {
      saved = await source.recordAnswer(question, answer);
    } catch (_) {
      if (!mounted || state.currentQuestion?.id != question.id) return;
      state = state.copyWith(isReviewSaveFailed: true);
      return;
    }
    if (!saved || !mounted || state.currentQuestion?.id != question.id) return;
    state = state.copyWith(isReviewSaved: true);
  }

  Future<void> _complete() async {
    if (state.isSubmitting || state.isComplete) return;
    if (state.answers.length != state.questions.length) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final attemptId = await source.complete(state);
      if (!mounted) return;
      state = state.copyWith(
        completed: true,
        attemptId: attemptId,
        isSubmitting: false,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: source.completeErrorMessage,
      );
    }
  }

  Future<void> retrySubmit() => _complete();
}

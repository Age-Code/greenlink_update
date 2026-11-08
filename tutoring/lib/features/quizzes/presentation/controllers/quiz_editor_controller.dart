import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';

typedef QuizEditorArgs = ({
  String classId,
  String userId,
  String? quizId,
});

final quizEditorControllerProvider = StateNotifierProvider.autoDispose.family<
    QuizEditorController, QuizEditorState, QuizEditorArgs>((ref, args) {
  return QuizEditorController(
    repository: ref.watch(quizRepositoryProvider),
    args: args,
  );
});

class QuizEditorState {
  const QuizEditorState({
    required this.quizId,
    required this.title,
    required this.description,
    required this.status,
    required this.questions,
    required this.createdAt,
    required this.publishedAt,
    required this.isLoading,
    required this.isSaving,
    required this.isDirty,
    required this.lastSavedAt,
    required this.errorMessage,
  });

  factory QuizEditorState.initial(String? quizId) => QuizEditorState(
    quizId: quizId,
    title: '',
    description: '',
    status: QuizStatus.draft,
    questions: const [],
    createdAt: DateTime.now(),
    publishedAt: null,
    isLoading: quizId != null,
    isSaving: false,
    isDirty: false,
    lastSavedAt: null,
    errorMessage: null,
  );

  final String? quizId;
  final String title;
  final String description;
  final QuizStatus status;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final bool isLoading;
  final bool isSaving;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final String? errorMessage;

  String? validationError({required bool forPublish}) {
    if (title.trim().isEmpty) return '퀴즈 제목을 입력해주세요.';
    if (!forPublish) return null;
    if (questions.isEmpty) return '문제를 하나 이상 작성해주세요.';
    for (var index = 0; index < questions.length; index++) {
      final error = questions[index].validationError;
      if (error != null) return '문제 ${index + 1}: $error';
    }
    return null;
  }

  QuizEditorState copyWith({
    String? quizId,
    String? title,
    String? description,
    QuizStatus? status,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? publishedAt,
    bool? isLoading,
    bool? isSaving,
    bool? isDirty,
    DateTime? lastSavedAt,
    String? errorMessage,
    bool clearPublishedAt = false,
    bool clearError = false,
  }) => QuizEditorState(
    quizId: quizId ?? this.quizId,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    questions: questions ?? this.questions,
    createdAt: createdAt ?? this.createdAt,
    publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    isDirty: isDirty ?? this.isDirty,
    lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class QuizEditorController extends StateNotifier<QuizEditorState> {
  QuizEditorController({required this.repository, required this.args})
      : super(QuizEditorState.initial(args.quizId)) {
    if (args.quizId != null) _load(args.quizId!);
  }

  final QuizRepository repository;
  final QuizEditorArgs args;

  Future<void> _load(String quizId) async {
    try {
      final results = await Future.wait([
        repository.getQuiz(args.classId, quizId),
        repository.getQuestions(args.classId, quizId),
      ]);
      final quiz = results[0] as StudyQuiz?;
      final questions = results[1] as List<QuizQuestion>;
      if (quiz == null) throw StateError('quiz not found');
      if (!mounted) return;
      state = state.copyWith(
        quizId: quiz.id,
        title: quiz.title,
        description: quiz.description,
        status: quiz.status,
        questions: _normalize(questions),
        createdAt: quiz.createdAt,
        publishedAt: quiz.publishedAt,
        isLoading: false,
        isDirty: false,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: '퀴즈를 불러오지 못했어요.',
      );
    }
  }

  void setTitle(String value) => _edit(state.copyWith(title: value));

  void setDescription(String value) =>
      _edit(state.copyWith(description: value));

  String addQuestion() {
    final id = 'question-${DateTime.now().microsecondsSinceEpoch}';
    final question = QuizQuestion(
      id: id,
      quizId: state.quizId ?? '',
      type: QuizQuestionType.multipleChoice,
      prompt: '',
      options: const ['', '', '', ''],
      correctOptionIndex: -1,
      explanation: '',
      order: state.questions.length,
      relatedNoteId: null,
      relatedBlockId: null,
    );
    _edit(state.copyWith(questions: [...state.questions, question]));
    return id;
  }

  void updateQuestion(QuizQuestion question) {
    _edit(
      state.copyWith(
        questions: state.questions
            .map((item) => item.id == question.id ? question : item)
            .toList(growable: false),
      ),
    );
  }

  void removeQuestion(String questionId) {
    _edit(
      state.copyWith(
        questions: _normalize(
          state.questions
              .where((question) => question.id != questionId)
              .toList(),
        ),
      ),
    );
  }

  void moveQuestion(String questionId, int direction) {
    final questions = [...state.questions];
    final index = questions.indexWhere((item) => item.id == questionId);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= questions.length) return;
    final question = questions.removeAt(index);
    questions.insert(target, question);
    _edit(state.copyWith(questions: _normalize(questions)));
  }

  Future<String?> save({QuizStatus? status}) async {
    final targetStatus = status ?? state.status;
    final error = state.validationError(
      forPublish: targetStatus == QuizStatus.published,
    );
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return null;
    }
    final now = DateTime.now();
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final quiz = StudyQuiz(
        id: state.quizId ?? '',
        classId: args.classId,
        title: state.title.trim(),
        description: state.description.trim(),
        createdBy: args.userId,
        status: targetStatus,
        questionCount: state.questions.length,
        createdAt: state.createdAt,
        updatedAt: now,
        publishedAt: targetStatus == QuizStatus.published
            ? state.publishedAt ?? now
            : null,
        noteId: null,
      );
      final quizId = await repository.saveQuiz(
        quiz: quiz,
        questions: _normalize(state.questions),
      );
      if (!mounted) return quizId;
      state = state.copyWith(
        quizId: quizId,
        status: targetStatus,
        questions: [
          for (final question in _normalize(state.questions))
            question.copyWith(quizId: quizId),
        ],
        publishedAt: targetStatus == QuizStatus.published
            ? state.publishedAt ?? now
            : null,
        isSaving: false,
        isDirty: false,
        lastSavedAt: now,
        clearPublishedAt: targetStatus == QuizStatus.draft,
        clearError: true,
      );
      return quizId;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(
        isSaving: false,
        errorMessage: '퀴즈를 저장하지 못했어요. 잠시 후 다시 시도해주세요.',
      );
      return null;
    }
  }

  void _edit(QuizEditorState next) {
    state = next.copyWith(isDirty: true, clearError: true);
  }

  List<QuizQuestion> _normalize(List<QuizQuestion> questions) => [
    for (var index = 0; index < questions.length; index++)
      questions[index].copyWith(order: index),
  ];
}

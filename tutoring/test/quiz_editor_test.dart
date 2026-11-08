import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_question.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_status.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_editor_controller.dart';

void main() {
  test('multiple choice question validates all required fields', () {
    final valid = _question('question-1', order: 0);
    expect(valid.isValid, isTrue);
    expect(valid.copyWith(prompt: '').validationError, contains('문제'));
    expect(
      valid.copyWith(options: const ['A', '', 'C', 'D']).validationError,
      contains('선택지'),
    );
    expect(
      valid.copyWith(correctOptionIndex: -1).validationError,
      contains('정답'),
    );
    expect(valid.copyWith(explanation: '').validationError, contains('해설'));
  });

  test('question related note and block can be replaced and cleared', () {
    final linked = _question('question-1', order: 0).copyWith(
      relatedNoteId: 'note-1',
      relatedBlockId: 'block-1',
    );

    expect(linked.relatedNoteId, 'note-1');
    expect(linked.relatedBlockId, 'block-1');
    expect(linked.copyWith(clearRelatedBlock: true).relatedNoteId, 'note-1');
    expect(linked.copyWith(clearRelatedBlock: true).relatedBlockId, isNull);
    expect(linked.copyWith(clearRelatedNote: true).relatedNoteId, isNull);
    expect(linked.copyWith(clearRelatedNote: true).relatedBlockId, isNull);
  });

  test('editor keeps multiple question order and saves a draft', () async {
    final repository = _FakeQuizRepository();
    final controller = QuizEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', quizId: null),
    );
    addTearDown(controller.dispose);

    controller.setTitle('Dictionary Quiz');
    final first = controller.addQuestion();
    final second = controller.addQuestion();
    controller.updateQuestion(_question(first, order: 0));
    controller.updateQuestion(_question(second, order: 1));
    controller.moveQuestion(second, -1);

    expect(controller.state.questions.map((item) => item.id), [second, first]);
    expect(controller.state.questions.map((item) => item.order), [0, 1]);

    final quizId = await controller.save();
    expect(quizId, 'quiz-1');
    expect(repository.savedQuiz?.status, QuizStatus.draft);
    expect(repository.savedQuestions.map((item) => item.order), [0, 1]);
  });

  test('publish rejects zero questions and publishes valid questions', () async {
    final repository = _FakeQuizRepository();
    final controller = QuizEditorController(
      repository: repository,
      args: (classId: 'class-1', userId: 'tutor-1', quizId: null),
    );
    addTearDown(controller.dispose);

    controller.setTitle('Dictionary Quiz');
    expect(
      await controller.save(status: QuizStatus.published),
      isNull,
    );
    expect(controller.state.errorMessage, contains('하나 이상'));

    final id = controller.addQuestion();
    controller.updateQuestion(_question(id, order: 0));
    expect(
      await controller.save(status: QuizStatus.published),
      'quiz-1',
    );
    expect(repository.savedQuiz?.status, QuizStatus.published);
    expect(repository.savedQuiz?.publishedAt, isNotNull);
  });
}

QuizQuestion _question(String id, {required int order}) => QuizQuestion(
  id: id,
  quizId: '',
  type: QuizQuestionType.multipleChoice,
  prompt: 'Dictionary에서 안전하게 key를 조회하는 방법은?',
  options: const ['[]', 'get()', 'find()', 'value()'],
  correctOptionIndex: 1,
  explanation: 'get()은 key가 없어도 KeyError를 발생시키지 않습니다.',
  order: order,
  relatedNoteId: null,
  relatedBlockId: null,
);

class _FakeQuizRepository implements QuizRepository {
  StudyQuiz? savedQuiz;
  List<QuizQuestion> savedQuestions = [];

  @override
  Future<String> saveQuiz({
    required StudyQuiz quiz,
    required List<QuizQuestion> questions,
  }) async {
    savedQuiz = quiz;
    savedQuestions = questions;
    return 'quiz-1';
  }

  @override
  Future<void> deleteQuiz(String classId, String quizId) async {}

  @override
  Future<List<QuizQuestion>> getQuestions(
    String classId,
    String quizId,
  ) async => savedQuestions;

  @override
  Future<StudyQuiz?> getQuiz(String classId, String quizId) async => savedQuiz;

  @override
  Future<void> setQuizStatus({
    required String classId,
    required String quizId,
    required QuizStatus status,
  }) async {
    savedQuiz = savedQuiz?.copyWith(
      status: status,
      clearPublishedAt: status == QuizStatus.draft,
    );
  }

  @override
  Stream<List<StudyQuiz>> watchAllQuizzes(String classId) =>
      const Stream.empty();

  @override
  Stream<List<StudyQuiz>> watchPublishedQuizzes(String classId) =>
      const Stream.empty();
}

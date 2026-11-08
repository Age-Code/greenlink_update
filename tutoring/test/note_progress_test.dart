import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_progress.dart';

import 'helpers/fake_repositories.dart';

NoteBlock _quiz(String id, {String? quizId = 'quiz-1', String? questionId}) =>
    NoteBlock(
      id: id,
      noteId: 'note-2',
      type: NoteBlockType.quiz,
      order: 0,
      content: '',
      language: null,
      quizId: quizId,
      questionId: questionId,
    );

void main() {
  test('a note without Quick Checks has no progress', () {
    expect(quickCheckProgress(sampleBlocks().take(4), const []), isNull);
    expect(
      quickCheckProgress([_quiz('x', questionId: null)], const []),
      isNull,
    );
  });

  test('progress counts Quick Checks answered in any saved attempt', () {
    final blocks = [
      _quiz('q1', questionId: 'question-1'),
      _quiz('q2', questionId: 'question-2'),
    ];
    final attempts = [
      sampleAttempt(
        id: 'inline',
        quizId: 'quiz-1',
        noteId: 'note-2',
        totalQuestions: 1,
        answers: [sampleAnswer('question-1', isCorrect: false)],
      ),
    ];

    expect(quickCheckProgress(blocks, const []), 0);
    expect(quickCheckProgress(blocks, attempts), 0.5);

    final fullQuiz = sampleAttempt(
      id: 'full',
      quizId: 'quiz-1',
      answers: [sampleAnswer('question-1'), sampleAnswer('question-2')],
    );
    expect(quickCheckProgress(blocks, [fullQuiz]), 1);
  });

  test('an attempt from another quiz does not count', () {
    final blocks = [_quiz('q1', questionId: 'question-1')];
    final other = sampleAttempt(
      id: 'other',
      quizId: 'quiz-9',
      answers: [sampleAnswer('question-1')],
    );

    expect(quickCheckProgress(blocks, [other]), 0);
  });
}

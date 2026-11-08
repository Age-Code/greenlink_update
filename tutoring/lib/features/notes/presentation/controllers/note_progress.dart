import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';

/// 학습 진행률 of a note = answered Quick Checks / Quick Checks in the note.
/// An answer counts once the learner saved an attempt that contains the
/// question, whether from the inline Quick Check or the full quiz.

/// Quick Check blocks that point at a real question.
List<NoteBlock> quickCheckBlocks(Iterable<NoteBlock> blocks) => blocks
    .where(
      (block) =>
          block.type == NoteBlockType.quiz &&
          block.quizId != null &&
          block.questionId != null,
    )
    .toList(growable: false);

/// Whether any saved attempt answered the question behind [block].
bool isQuickCheckDone(NoteBlock block, Iterable<QuizAttempt> attempts) =>
    attempts.any(
      (attempt) =>
          attempt.quizId == block.quizId &&
          attempt.answers.any(
            (answer) => answer.questionId == block.questionId,
          ),
    );

/// 0..1, or null when the note has no Quick Check so the badge can stay
/// hidden instead of showing a meaningless 0%.
double? quickCheckProgress(
  Iterable<NoteBlock> blocks,
  Iterable<QuizAttempt> attempts,
) {
  final checks = quickCheckBlocks(blocks);
  if (checks.isEmpty) return null;
  final done =
      checks.where((block) => isQuickCheckDone(block, attempts)).length;
  return done / checks.length;
}

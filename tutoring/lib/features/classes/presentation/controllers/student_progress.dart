import 'dart:math' as math;

import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';

/// Pure helpers behind the student class home numbers.

/// Attempts that belong to [quiz] in its current shape. An attempt made
/// before the tutor changed the question count no longer matches.
List<QuizAttempt> attemptsForQuiz(
  StudyQuiz quiz,
  Iterable<QuizAttempt> attempts,
) => attempts
    .where(
      (attempt) =>
          attempt.quizId == quiz.id &&
          attempt.totalQuestions == quiz.questionCount,
    )
    .toList(growable: false);

/// Published quizzes the learner has never finished.
List<StudyQuiz> unsolvedQuizzes(
  List<StudyQuiz> quizzes,
  List<QuizAttempt> attempts,
) => quizzes
    .where((quiz) => attemptsForQuiz(quiz, attempts).isEmpty)
    .toList(growable: false);

/// 학습 달성도 = finished quizzes / published quizzes (0 when none published).
double quizCompletionProgress(
  List<StudyQuiz> quizzes,
  List<QuizAttempt> attempts,
) {
  if (quizzes.isEmpty) return 0;
  final done = quizzes.length - unsolvedQuizzes(quizzes, attempts).length;
  return done / quizzes.length;
}

/// Reading estimate for a note: about 1.5 minutes per block, at least 5.
int estimatedReadingMinutes(int blockCount) =>
    math.max(5, (blockCount * 1.5).round());

/// When the learner last finished something in this class, if ever.
DateTime? latestStudyTime(Iterable<QuizAttempt> attempts) {
  DateTime? latest;
  for (final attempt in attempts) {
    if (latest == null || attempt.completedAt.isAfter(latest)) {
      latest = attempt.completedAt;
    }
  }
  return latest;
}

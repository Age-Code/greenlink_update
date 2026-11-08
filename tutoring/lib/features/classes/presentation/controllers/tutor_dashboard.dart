import 'package:tutoring/features/classes/domain/entities/class_member.dart';
import 'package:tutoring/features/classes/presentation/controllers/student_progress.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/domain/entities/study_quiz.dart';

/// Pure aggregation behind the tutor's 학습 현황 section (13_Tutor_Class_Home).
///
/// Everything is derived from the students' quiz attempts, the only learner
/// record a tutor may read. Notes count as "touched" when the student solved
/// a Quick Check inside them; reading alone leaves no record yet.

class StudentProgress {
  const StudentProgress({
    required this.member,
    required this.quizzesDone,
    required this.quizTotal,
    required this.notesTouched,
    required this.noteTotal,
    required this.lastStudied,
    required this.currentNote,
  });

  final ClassMember member;
  final int quizzesDone;
  final int quizTotal;
  final int notesTouched;
  final int noteTotal;
  final DateTime? lastStudied;

  /// Note of the student's latest activity, if it can be identified.
  final StudyNote? currentNote;

  String get name => member.displayName;

  /// Same rule as the student's own 학습 달성도: finished quizzes over
  /// published quizzes.
  double get progress => quizTotal == 0 ? 0 : quizzesDone / quizTotal;

  int get progressPercent => (progress * 100).round();

  bool activeSince(DateTime threshold) {
    final time = lastStudied;
    return time != null && time.isAfter(threshold);
  }
}

/// One row per student (members who are not the tutor), most recently
/// active first.
List<StudentProgress> buildStudentProgress({
  required List<ClassMember> members,
  required List<StudyNote> publishedNotes,
  required List<StudyQuiz> publishedQuizzes,
  required List<QuizAttempt> attempts,
}) {
  final notesById = {for (final note in publishedNotes) note.id: note};
  final quizzesById = {for (final quiz in publishedQuizzes) quiz.id: quiz};
  final rows = <StudentProgress>[];
  for (final member in members.where((member) => !member.isTutor)) {
    final own = attempts
        .where((attempt) => attempt.userId == member.uid)
        .toList(growable: false);
    final quizzesDone =
        publishedQuizzes
            .where((quiz) => attemptsForQuiz(quiz, own).isNotEmpty)
            .length;
    final touched = <String>{
      for (final attempt in own)
        if (attempt.noteId != null && notesById.containsKey(attempt.noteId))
          attempt.noteId!,
    };
    QuizAttempt? latest;
    for (final attempt in own) {
      if (latest == null || attempt.completedAt.isAfter(latest.completedAt)) {
        latest = attempt;
      }
    }
    StudyNote? currentNote;
    if (latest != null) {
      currentNote =
          notesById[latest.noteId] ??
          notesById[quizzesById[latest.quizId]?.noteId];
    }
    rows.add(
      StudentProgress(
        member: member,
        quizzesDone: quizzesDone,
        quizTotal: publishedQuizzes.length,
        notesTouched: touched.length,
        noteTotal: publishedNotes.length,
        lastStudied: latest?.completedAt,
        currentNote: currentNote,
      ),
    );
  }
  rows.sort((a, b) {
    final at = a.lastStudied, bt = b.lastStudied;
    if (at == null && bt == null) return a.name.compareTo(b.name);
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  return rows;
}

/// Mean of the students' progress; 0 without students.
double averageProgress(List<StudentProgress> students) {
  if (students.isEmpty) return 0;
  final sum = students.fold<double>(0, (total, s) => total + s.progress);
  return sum / students.length;
}

/// Students who finished something in the last seven days.
int activeThisWeek(List<StudentProgress> students, {DateTime? now}) {
  final threshold = (now ?? DateTime.now()).subtract(const Duration(days: 7));
  return students.where((s) => s.activeSince(threshold)).length;
}

/// 평균 제출율: for each published quiz, the share of students who finished
/// it, averaged over quizzes. 0 without students or quizzes.
double submissionRate({
  required List<StudentProgress> students,
  required List<StudyQuiz> publishedQuizzes,
  required List<QuizAttempt> attempts,
}) {
  if (students.isEmpty || publishedQuizzes.isEmpty) return 0;
  var total = 0.0;
  for (final quiz in publishedQuizzes) {
    final done =
        students
            .where(
              (s) =>
                  attemptsForQuiz(
                    quiz,
                    attempts.where((a) => a.userId == s.member.uid),
                  ).isNotEmpty,
            )
            .length;
    total += done / students.length;
  }
  return total / publishedQuizzes.length;
}

/// "2026년 1학기" for March–August, "2학기" otherwise (January and February
/// belong to the previous year's second term).
String semesterLabel(DateTime date) {
  if (date.month >= 3 && date.month <= 8) return '${date.year}년 1학기';
  final year = date.month <= 2 ? date.year - 1 : date.year;
  return '$year년 2학기';
}

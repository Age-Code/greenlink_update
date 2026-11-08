abstract final class AppRoutes {
  static const onboarding = '/';
  static const login = '/login';
  static const register = '/register';
  static const roleSelection = '/role-selection';
  static const home = '/home';
  static const my = '/my';
  static const policyPath = '/my/policy/:kind';
  static const classPath = '/classes/:classId';
  static const classNotesPath = '/classes/:classId/notes';
  static const noteReaderPath = '/classes/:classId/notes/:noteId';
  static const tutorNotesPath = '/classes/:classId/manage/notes';
  static const newTutorNotePath = '/classes/:classId/manage/notes/new';
  static const editTutorNotePath =
      '/classes/:classId/manage/notes/:noteId/edit';
  static const tutorQuizzesPath = '/classes/:classId/manage/quizzes';
  static const newTutorQuizPath = '/classes/:classId/manage/quizzes/new';
  static const editTutorQuizPath =
      '/classes/:classId/manage/quizzes/:quizId/edit';
  static const tuteeQuizzesPath = '/classes/:classId/quizzes';
  static const solveQuizPath = '/classes/:classId/quizzes/:quizId/solve';
  static const classReviewPath = '/classes/:classId/review';
  static const reviewSessionPath = '/classes/:classId/review/session';
  static const reviewDetailPath = '/classes/:classId/review/:reviewId';

  static String policy(String kind) => '/my/policy/$kind';
  static String classDetail(String classId) => '/classes/$classId';
  static String classNotes(String classId) => '/classes/$classId/notes';
  static String noteReader(
    String classId,
    String noteId, {
    String? targetBlockId,
  }) {
    final path = '/classes/$classId/notes/$noteId';
    if (targetBlockId == null || targetBlockId.isEmpty) return path;
    return Uri(
      path: path,
      queryParameters: {'targetBlockId': targetBlockId},
    ).toString();
  }

  static String tutorNotes(String classId) => '/classes/$classId/manage/notes';
  static String newTutorNote(String classId) =>
      '/classes/$classId/manage/notes/new';
  static String editTutorNote(String classId, String noteId) =>
      '/classes/$classId/manage/notes/$noteId/edit';
  static String tutorQuizzes(String classId) =>
      '/classes/$classId/manage/quizzes';
  static String newTutorQuiz(String classId) =>
      '/classes/$classId/manage/quizzes/new';
  static String editTutorQuiz(String classId, String quizId) =>
      '/classes/$classId/manage/quizzes/$quizId/edit';
  static String tuteeQuizzes(String classId) => '/classes/$classId/quizzes';
  static String solveQuiz(String classId, String quizId) =>
      '/classes/$classId/quizzes/$quizId/solve';
  static String classReview(String classId) => '/classes/$classId/review';
  static String reviewDetail(String classId, String reviewId) =>
      '/classes/$classId/review/$reviewId';

  /// Inverse of [reviewSession]: the review ids carried by the `ids` query.
  static List<String> parseReviewSessionIds(String? query) =>
      query == null
          ? const []
          : query
              .split(',')
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false);

  /// Retry session over the given review ids (comma-separated `ids` query).
  static String reviewSession(String classId, {required Iterable<String> ids}) {
    final joined = ids.join(',');
    return Uri(
      path: '/classes/$classId/review/session',
      queryParameters: joined.isEmpty ? null : {'ids': joined},
    ).toString();
  }
}

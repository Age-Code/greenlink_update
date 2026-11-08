import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/auth/presentation/screens/login_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/register_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:tutoring/features/classes/presentation/screens/class_home_screen.dart';
import 'package:tutoring/features/home/presentation/home_screen.dart';
import 'package:tutoring/features/profile/presentation/screens/my_screen.dart';
import 'package:tutoring/features/profile/presentation/screens/policy_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/note_reader_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/tutor_note_editor_screen.dart';
import 'package:tutoring/features/notes/presentation/screens/tutor_notes_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutor_quiz_editor_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutor_quiz_list_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/tutee_quiz_list_screen.dart';
import 'package:tutoring/features/quizzes/presentation/screens/quiz_solve_screen.dart';
import 'package:tutoring/features/reviews/presentation/screens/class_review_screen.dart';
import 'package:tutoring/features/reviews/presentation/screens/review_session_screen.dart';
import 'package:tutoring/features/reviews/presentation/screens/review_detail_screen.dart';

/// Whether the stored profile already has a role. A failed read (offline,
/// permissions) counts as "no role" so the user still reaches a screen.
Future<bool> _hasRole(Ref ref, String uid) async {
  try {
    final profile = await ref.read(userProfileProvider(uid).future);
    return profile?.role != null;
  } catch (_) {
    return false;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final user = authState.asData?.value;
      final protected =
          state.matchedLocation == AppRoutes.home ||
          state.matchedLocation == AppRoutes.roleSelection ||
          state.matchedLocation.startsWith('/classes/') ||
          state.matchedLocation.startsWith('/my');
      if (protected && user == null && !authState.isLoading) {
        return AppRoutes.login;
      }
      // Role selection is a one-time step: a user whose profile already
      // carries a role lands on the home instead (role changes live in 마이).
      if (user != null && state.matchedLocation == AppRoutes.roleSelection) {
        if (await _hasRole(ref, user.uid)) return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const StudyTogetherRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (_, _) => const RoleSelectionScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: AppRoutes.my, builder: (_, _) => const MyScreen()),
      GoRoute(
        path: AppRoutes.policyPath,
        builder:
            (_, state) => PolicyScreen(kindSlug: state.pathParameters['kind']!),
      ),
      GoRoute(
        path: AppRoutes.classPath,
        builder:
            (_, state) =>
                ClassHomeScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: AppRoutes.classNotesPath,
        builder:
            (_, state) =>
                NotesListScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: AppRoutes.noteReaderPath,
        builder:
            (_, state) => NoteReaderScreen(
              classId: state.pathParameters['classId']!,
              noteId: state.pathParameters['noteId']!,
              targetBlockId: state.uri.queryParameters['targetBlockId'],
            ),
      ),
      GoRoute(
        path: AppRoutes.tutorNotesPath,
        builder:
            (_, state) =>
                TutorNotesScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: AppRoutes.newTutorNotePath,
        builder:
            (_, state) => TutorNoteEditorScreen(
              classId: state.pathParameters['classId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.editTutorNotePath,
        builder:
            (_, state) => TutorNoteEditorScreen(
              classId: state.pathParameters['classId']!,
              noteId: state.pathParameters['noteId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.tutorQuizzesPath,
        builder:
            (_, state) =>
                TutorQuizListScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: AppRoutes.newTutorQuizPath,
        builder:
            (_, state) => TutorQuizEditorScreen(
              classId: state.pathParameters['classId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.editTutorQuizPath,
        builder:
            (_, state) => TutorQuizEditorScreen(
              classId: state.pathParameters['classId']!,
              quizId: state.pathParameters['quizId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.tuteeQuizzesPath,
        builder:
            (_, state) =>
                TuteeQuizListScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: AppRoutes.solveQuizPath,
        builder:
            (_, state) => QuizSolveScreen(
              classId: state.pathParameters['classId']!,
              quizId: state.pathParameters['quizId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.classReviewPath,
        builder:
            (_, state) =>
                ClassReviewScreen(classId: state.pathParameters['classId']!),
      ),
      // `session` must be registered before `:reviewId` so it is not read as an id.
      GoRoute(
        path: AppRoutes.reviewSessionPath,
        builder:
            (_, state) => ReviewSessionScreen(
              classId: state.pathParameters['classId']!,
              reviewIds: AppRoutes.parseReviewSessionIds(
                state.uri.queryParameters['ids'],
              ),
            ),
      ),
      GoRoute(
        path: AppRoutes.reviewDetailPath,
        builder:
            (_, state) => ReviewDetailScreen(
              classId: state.pathParameters['classId']!,
              reviewId: state.pathParameters['reviewId']!,
            ),
      ),
    ],
  );
  ref.listen(authStateProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

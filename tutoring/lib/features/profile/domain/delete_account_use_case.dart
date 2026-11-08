import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/domain/repositories/auth_repository.dart';
import 'package:tutoring/features/classes/domain/repositories/class_repository.dart';
import 'package:tutoring/features/notes/domain/repositories/annotation_repository.dart';
import 'package:tutoring/features/profile/domain/account_reauth.dart';
import 'package:tutoring/features/quizzes/domain/repositories/quiz_attempt_repository.dart';
import 'package:tutoring/features/reviews/domain/repositories/review_repository.dart';

/// Deletes the signed-in user's account and every document they own.
///
/// Order matters: a tutor who still owns classes is refused before anything
/// changes; identity is confirmed next so the final Auth deletion cannot fail
/// on `requires-recent-login` after data is already gone; then class
/// memberships, annotations, reviews, attempts and the profile are removed,
/// and the Firebase Auth user last. If a step fails the account survives and
/// the caller shows the error.
class DeleteAccountUseCase {
  const DeleteAccountUseCase({
    required this.auth,
    required this.classes,
    required this.annotations,
    required this.attempts,
    required this.reviews,
  });

  final AuthRepository auth;
  final ClassRepository classes;
  final AnnotationRepository annotations;
  final QuizAttemptRepository attempts;
  final ReviewRepository reviews;

  Future<void> call({
    required String userId,
    required AccountReauth reauth,
  }) async {
    if (await classes.ownsAnyClass(userId)) {
      throw const AccountDeletionBlockedException();
    }
    switch (reauth) {
      case PasswordReauth(:final password):
        await auth.reauthenticateWithPassword(password);
      case GoogleReauth():
        await auth.reauthenticateWithGoogle();
    }
    for (final studyClass in await classes.getMyClasses(userId)) {
      await classes.leaveClass(userId: userId, classId: studyClass.id);
    }
    await annotations.deleteAllForUser(userId);
    await reviews.deleteAllForUser(userId);
    await attempts.deleteAllForUser(userId);
    await auth.deleteProfile(userId);
    await auth.deleteAccount();
  }
}

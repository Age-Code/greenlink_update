import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/auth/presentation/controllers/role_controller.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/profile/domain/account_reauth.dart';
import 'package:tutoring/features/profile/domain/delete_account_use_case.dart';
import 'package:tutoring/features/quizzes/data/quiz_data_providers.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => DeleteAccountUseCase(
    auth: ref.watch(authRepositoryProvider),
    classes: ref.watch(classRepositoryProvider),
    annotations: ref.watch(annotationRepositoryProvider),
    attempts: ref.watch(quizAttemptRepositoryProvider),
    reviews: ref.watch(reviewRepositoryProvider),
  ),
);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

/// Actions of the 마이 screen. Every method returns whether it succeeded;
/// the error, if any, is on [state] for the screen to show.
class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateName({required String uid, required String name}) =>
      _run(() async {
        final trimmed = name.trim();
        await ref
            .read(authRepositoryProvider)
            .updateName(uid: uid, name: trimmed);
        try {
          await ref
              .read(classRepositoryProvider)
              .updateMemberName(userId: uid, name: trimmed);
        } catch (_) {
          // The class-side name snapshot is a convenience for tutors; the
          // profile rename itself has already succeeded.
        }
        ref.invalidate(userProfileProvider(uid));
      });

  Future<bool> changeRole(UserRole role) async {
    // The role controller stays in its loading state until its build has
    // run; nothing else on this screen watches it, so wait for that first or
    // the first call would be dropped.
    await ref.read(roleControllerProvider.future);
    return ref.read(roleControllerProvider.notifier).selectRole(role);
  }

  Future<bool> sendPasswordReset(String email) => _run(
    () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
  );

  Future<bool> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<bool> deleteAccount({
    required String uid,
    required AccountReauth reauth,
  }) => _run(
    () => ref.read(deleteAccountUseCaseProvider)(userId: uid, reauth: reauth),
  );

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  String messageFor(Object error) => switch (error) {
    AppException exception => exception.userMessage,
    _ => '잠시 후 다시 시도해 주세요.',
  };
}

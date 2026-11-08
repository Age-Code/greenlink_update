import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInWithApple();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserProfile?> getProfile(String uid);

  Future<void> saveRole({required String uid, required UserRole role});

  Future<void> updateName({required String uid, required String name});

  /// Confirms the signed-in user's identity right before a sensitive action
  /// such as deleting the account.
  Future<void> reauthenticateWithPassword(String password);

  Future<void> reauthenticateWithGoogle();

  /// Removes `users/{uid}`; the account itself is deleted by [deleteAccount].
  Future<void> deleteProfile(String uid);

  /// Deletes the signed-in Firebase Auth user. Requires a recent sign-in,
  /// so call one of the reauthenticate methods first.
  Future<void> deleteAccount();

  Future<void> signOut();
}

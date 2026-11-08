import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({
    required String email,
    required String password,
  }) => _run(() async {
    await ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email.trim(), password: password);
  });

  Future<bool> signUp({
    required String email,
    required String password,
  }) => _run(() async {
    await ref
        .read(authRepositoryProvider)
        .signUpWithEmail(email: email.trim(), password: password);
  });

  Future<bool> signInWithGoogle() => _run(() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  });

  Future<bool> signInWithApple() => _run(() async {
    await ref.read(authRepositoryProvider).signInWithApple();
  });

  Future<bool> sendPasswordResetEmail(String email) => _run(
    () => ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email.trim()),
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

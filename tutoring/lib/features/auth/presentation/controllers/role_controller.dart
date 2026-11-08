import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';

final roleControllerProvider =
    AsyncNotifierProvider<RoleController, void>(RoleController.new);

final selectedRoleProvider = StateProvider<UserRole?>((ref) => null);

class RoleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> selectRole(UserRole role) async {
    if (state.isLoading) return false;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .saveRole(uid: user.uid, role: role);
      ref.read(selectedRoleProvider.notifier).state = role;
      ref.invalidate(userProfileProvider(user.uid));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

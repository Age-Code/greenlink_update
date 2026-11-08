import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/auth/data/auth_data_providers.dart';
import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';

export 'package:tutoring/features/auth/data/auth_data_providers.dart'
    show authRepositoryProvider;

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(authRepositoryProvider).getProfile(uid);
});

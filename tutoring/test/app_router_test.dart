import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/router/app_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_theme.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/auth/presentation/screens/login_screen.dart';
import 'package:tutoring/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:tutoring/features/home/presentation/home_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

/// The real app router over fake repositories.
Widget _app(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: Consumer(
    builder:
        (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: ref.watch(appRouterProvider),
        ),
  ),
);

Future<void> _go(WidgetTester tester, String location) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  container.read(appRouterProvider).go(location);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a user who already picked a role skips role selection', (
    tester,
  ) async {
    await tester.pumpAtSize(
      _app(signedInOverrides(user: tuteeUser, role: UserRole.tutee)),
      TestScreenSizes.tablet,
    );
    await _go(tester, AppRoutes.roleSelection);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
  });

  testWidgets('a user without a role still sees role selection', (
    tester,
  ) async {
    final profile = UserProfile(
      uid: tuteeUser.uid,
      email: tuteeUser.email,
      name: '새 사용자',
      role: null,
      profileImageUrl: null,
      createdAt: testDate,
    );
    await tester.pumpAtSize(
      _app(signedInOverrides(user: tuteeUser, profile: profile)),
      TestScreenSizes.tablet,
    );
    await _go(tester, AppRoutes.roleSelection);

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets('signed-out users are sent to login from protected routes', (
    tester,
  ) async {
    await tester.pumpAtSize(
      _app([
        ...signedInOverrides(user: tuteeUser),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: null),
        ),
      ]),
      TestScreenSizes.tablet,
    );
    await _go(tester, AppRoutes.home);

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

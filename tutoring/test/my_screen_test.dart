import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/profile/presentation/content/policy_texts.dart';
import 'package:tutoring/features/profile/presentation/screens/my_screen.dart';
import 'package:tutoring/features/profile/presentation/screens/policy_screen.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/screen_sizes.dart';

const _passwordUser = AuthUser(
  uid: 'tutee-1',
  email: 'tutee@example.com',
  providerIds: ['password'],
);

class _Stub extends StatelessWidget {
  const _Stub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.my,
  routes: [
    GoRoute(path: AppRoutes.my, builder: (_, _) => const MyScreen()),
    GoRoute(
      path: AppRoutes.policyPath,
      builder:
          (_, state) => PolicyScreen(kindSlug: state.pathParameters['kind']!),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const _Stub('home')),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const _Stub('login')),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const _Stub('onboarding'),
    ),
  ],
);

Widget _app({
  AuthUser user = tuteeUser,
  UserRole role = UserRole.tutee,
  List<StudyClass>? classes,
  List<String>? log,
}) => buildSignedInApp(
  router: _router(),
  user: user,
  role: role,
  classes: classes,
  reviews: FakeReviewRepository(sampleReviews(), log),
  log: log,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testAtScreenSizes(
    '마이 shows profile, learning summary and the four sections',
    _app,
    sizes: TestScreenSizes.allWithNarrowTablet,
    verify: (tester, size) async {
      expect(find.text('이튜티'), findsWidgets);
      expect(find.text('tutee@example.com'), findsOneWidget);
      expect(find.text('튜티'), findsOneWidget);
      expect(find.text('참여 클래스'), findsOneWidget);
      expect(find.text('1개'), findsNWidgets(1));
      expect(find.text('푼 퀴즈'), findsOneWidget);
      expect(find.text('1번'), findsOneWidget);
      expect(find.text('남은 복습'), findsOneWidget);
      expect(find.text('2개'), findsOneWidget);
      expect(find.text('이름 수정'), findsOneWidget);
      expect(find.text('역할 변경'), findsOneWidget);
      expect(find.text('비밀번호 재설정 메일 보내기'), findsNothing);
      expect(find.text('개인정보 처리방침'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('회원 탈퇴'), findsOneWidget);
      // The title says 마이; below desktop the bottom tab repeats it.
      expect(
        find.text('마이'),
        size.width >= 1200 ? findsOneWidget : findsNWidgets(2),
      );
    },
  );

  testWidgets('a tutor sees classes, notes and students', (tester) async {
    await tester.pumpAtSize(
      _app(user: tutorUser, role: UserRole.tutor, classes: [sampleClass()]),
      TestScreenSizes.tablet,
    );
    expect(find.text('튜터'), findsOneWidget);
    expect(find.text('운영 클래스'), findsOneWidget);
    expect(find.text('작성 노트'), findsOneWidget);
    expect(find.text('3개'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);
    expect(find.text('4명'), findsOneWidget);
  });

  testWidgets('password accounts can request a reset mail', (tester) async {
    final log = <String>[];
    await tester.pumpAtSize(
      _app(user: _passwordUser, log: log),
      TestScreenSizes.tablet,
    );
    await tester.tap(find.text('비밀번호 재설정 메일 보내기'));
    await _settle(tester);
    expect(log, contains('auth.resetMail:tutee@example.com'));
    expect(find.textContaining('재설정 메일을 보냈어요'), findsOneWidget);
  });

  testWidgets('renaming updates the profile and the class snapshot', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpAtSize(_app(log: log), TestScreenSizes.tablet);

    await tester.tap(find.text('이름 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '새이름');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await _settle(tester);

    expect(log, ['auth.updateName:새이름', 'classes.memberName:새이름']);
    expect(find.text('이름을 바꿨어요.'), findsOneWidget);
  });

  testWidgets('changing the role asks first, then saves', (tester) async {
    final log = <String>[];
    await tester.pumpAtSize(_app(log: log), TestScreenSizes.tablet);

    await tester.tap(find.text('역할 변경'));
    await tester.pumpAndSettle();
    expect(find.text('튜터로 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('바꾸기'));
    await _settle(tester);

    expect(log, ['auth.saveRole:tutor']);
  });

  testWidgets('policy tiles open the draft documents', (tester) async {
    await tester.pumpAtSize(_app(), TestScreenSizes.desktop);
    await tester.tap(find.text('내 데이터 안내'));
    await tester.pumpAndSettle();
    expect(find.text(policyDraftNotice), findsOneWidget);
    expect(find.text('탈퇴하면'), findsOneWidget);
  });

  testWidgets('logging out returns to the login screen', (tester) async {
    final log = <String>[];
    await tester.pumpAtSize(_app(log: log), TestScreenSizes.phone);
    // The 계정 section sits below the fold on a phone.
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await _settle(tester);
    expect(log, ['auth.signOut']);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('deleting a password account runs the whole flow', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpAtSize(
      _app(user: _passwordUser, log: log),
      TestScreenSizes.tablet,
    );

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, '탈퇴하기');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(find.byKey(MyScreen.deleteConfirmFieldKey), '탈퇴');
    await tester.enterText(find.byKey(MyScreen.deletePasswordFieldKey), 'pw');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await _settle(tester);

    expect(log, [
      'auth.reauth.password',
      'classes.leave:class-1',
      'annotations.deleteAll',
      'reviews.deleteAll',
      'attempts.deleteAll',
      'auth.deleteProfile',
      'auth.deleteAccount',
    ]);
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('a tutor with classes is told to clean up first', (tester) async {
    final log = <String>[];
    await tester.pumpAtSize(
      _app(
        user: tutorUser,
        role: UserRole.tutor,
        classes: [sampleClass()],
        log: log,
      ),
      TestScreenSizes.tablet,
    );

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google 로그인 창'), findsOneWidget);
    await tester.enterText(find.byKey(MyScreen.deleteConfirmFieldKey), '탈퇴');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '탈퇴하기'));
    await _settle(tester);

    expect(log, isEmpty);
    expect(find.textContaining('아직 운영 중인 클래스가 있어요'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
  });
}

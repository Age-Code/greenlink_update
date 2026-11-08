import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/errors/app_exception.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/profile/domain/account_reauth.dart';
import 'package:tutoring/features/profile/domain/delete_account_use_case.dart';

import 'helpers/fake_repositories.dart';

void main() {
  late List<String> log;
  late FakeAuthRepository auth;
  late FakeClassRepository classes;
  late DeleteAccountUseCase useCase;

  DeleteAccountUseCase build({bool failReauth = false}) {
    log = [];
    auth = FakeAuthRepository(
      user: tuteeUser,
      profile: profileFor(tuteeUser, UserRole.tutee),
      log: log,
      failReauth: failReauth,
    );
    classes = FakeClassRepository([sampleClass()], log: log);
    return DeleteAccountUseCase(
      auth: auth,
      classes: classes,
      annotations: FakeAnnotationRepository(const [], log),
      attempts: FakeQuizAttemptRepository(const [], log: log),
      reviews: FakeReviewRepository(sampleReviews(), log),
    );
  }

  test(
    'confirms identity first, then removes data, then the account',
    () async {
      useCase = build();

      await useCase(userId: tuteeUser.uid, reauth: const GoogleReauth());

      expect(log, [
        'auth.reauth.google',
        'classes.leave:class-1',
        'annotations.deleteAll',
        'reviews.deleteAll',
        'attempts.deleteAll',
        'auth.deleteProfile',
        'auth.deleteAccount',
      ]);
    },
  );

  test('a password account reauthenticates with the password', () async {
    useCase = build();

    await useCase(
      userId: tuteeUser.uid,
      reauth: const PasswordReauth('secret'),
    );

    expect(log.first, 'auth.reauth.password');
    expect(log.last, 'auth.deleteAccount');
  });

  test(
    'a tutor who still owns a class is refused before anything changes',
    () async {
      useCase = build();

      await expectLater(
        useCase(userId: tutorUser.uid, reauth: const GoogleReauth()),
        throwsA(isA<AccountDeletionBlockedException>()),
      );
      expect(log, isEmpty);
    },
  );

  test('a failed reauthentication stops before any deletion', () async {
    useCase = build(failReauth: true);

    await expectLater(
      useCase(userId: tuteeUser.uid, reauth: const PasswordReauth('wrong')),
      throwsA(isA<AuthException>()),
    );
    expect(log, ['auth.reauth.password']);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_writer.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';

import 'helpers/fake_repositories.dart';

void main() {
  late List<String> log;
  late FakeNotificationRepository notifications;

  ProviderContainer tutorContainer({bool failWrites = false}) {
    log = [];
    notifications = FakeNotificationRepository(
      log: log,
      failWrites: failWrites,
    );
    final container = ProviderContainer(
      overrides: signedInOverrides(
        user: tutorUser,
        role: UserRole.tutor,
        notificationRepository: notifications,
        blocks: sampleBlocks(
          noteId: 'note-1',
        ).where((block) => block.quizId == null).toList(growable: false),
        log: log,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a published note becomes a notePublished notification', () async {
    final container = tutorContainer();
    await container.read(authStateProvider.future);
    await container.read(userProfileProvider(tutorUser.uid).future);

    await container
        .read(notificationWriterProvider)
        .notePublished(classId: 'class-1', noteId: 'note-3', noteTitle: '딕셔너리');

    final item = notifications.items.single;
    expect(item.type, NotificationType.notePublished);
    expect(item.actorId, tutorUser.uid);
    expect(item.actorName, '김튜터');
    expect(item.targetId, 'note-3');
    expect(item.body, '딕셔너리');
  });

  test('a failed write never surfaces to the caller', () async {
    final container = tutorContainer(failWrites: true);
    await container.read(authStateProvider.future);

    await container
        .read(notificationWriterProvider)
        .quizPublished(classId: 'class-1', quizId: 'quiz-1', quizTitle: 'Quiz');

    expect(notifications.items, isEmpty);
  });

  test('publishing a quiz from the list notifies the class', () async {
    final container = tutorContainer();
    await container.read(authStateProvider.future);

    final error = await container
        .read(quizActionControllerProvider.notifier)
        .publish(classId: 'class-1', quizId: 'quiz-1');

    expect(error, isNull);
    expect(log, [
      'quizzes.status:quiz-1:published',
      'notifications.create:quizPublished:class-1',
    ]);
  });

  test('publishing a draft note from the list notifies the class', () async {
    final container = tutorContainer();
    await container.read(authStateProvider.future);
    await container.read(noteActionControllerProvider.future);

    final error = await container
        .read(noteActionControllerProvider.notifier)
        .publishNote(classId: 'class-1', noteId: 'note-1');

    expect(error, isNull);
    expect(log, [
      'notes.status:note-1:published',
      'notifications.create:notePublished:class-1',
    ]);
  });

  test('joining a class notifies its tutor', () async {
    log = [];
    notifications = FakeNotificationRepository(log: log);
    final container = ProviderContainer(
      overrides: signedInOverrides(
        user: tuteeUser,
        notificationRepository: notifications,
        log: log,
      ),
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);
    await container.read(classActionControllerProvider.future);

    final joined = await container
        .read(classActionControllerProvider.notifier)
        .joinClass(
          userId: tuteeUser.uid,
          userName: '이튜티',
          inviteCode: 'ABCD1234',
        );

    expect(joined?.id, 'class-1');
    expect(log, [
      'classes.join:class-1',
      'notifications.create:memberJoined:class-1',
    ]);
    expect(notifications.items.single.body, '이튜티님이 클래스에 들어왔어요.');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_feed.dart';

import 'helpers/fake_repositories.dart';

void main() {
  final classes = {'class-1': sampleClass()};
  final note = sampleNotification(
    id: 'n-note',
    type: NotificationType.notePublished,
    createdAt: testDate.add(const Duration(hours: 1)),
  );
  final quiz = sampleNotification(
    id: 'n-quiz',
    type: NotificationType.quizPublished,
    targetId: 'quiz-1',
    createdAt: testDate.add(const Duration(hours: 2)),
  );
  final joined = sampleNotification(
    id: 'n-join',
    type: NotificationType.memberJoined,
    actorId: 'tutee-2',
    targetId: 'tutee-2',
    createdAt: testDate.add(const Duration(hours: 3)),
  );

  test('students see publishes, newest first, and never joins', () {
    final visible = visibleNotifications(
      [note, quiz, joined],
      userId: 'tutee-1',
      classesById: classes,
    );
    expect(visible.map((item) => item.id), ['n-quiz', 'n-note']);
  });

  test('the tutor sees joins but not their own publishes', () {
    final visible = visibleNotifications(
      [note, quiz, joined],
      userId: 'tutor-1',
      classesById: classes,
    );
    expect(visible.map((item) => item.id), ['n-join']);
  });

  test('items of a class the user no longer belongs to are dropped', () {
    final visible = visibleNotifications(
      [note],
      userId: 'tutee-1',
      classesById: const {},
    );
    expect(visible, isEmpty);
  });

  test('unread counts items after the seen time', () {
    expect(unreadCount([note, quiz], null), 2);
    expect(
      unreadCount([note, quiz], testDate.add(const Duration(hours: 1))),
      1,
    );
    expect(
      unreadCount([note, quiz], testDate.add(const Duration(hours: 3))),
      0,
    );
  });

  test('routes lead to the reader, the quiz list or the class home', () {
    expect(notificationRoute(note), '/classes/class-1/notes/note-3');
    expect(notificationRoute(quiz), '/classes/class-1/quizzes');
    expect(notificationRoute(joined), '/classes/class-1');
    final noTarget = sampleNotification(
      id: 'x',
      type: NotificationType.notePublished,
      targetId: null,
    );
    expect(notificationRoute(noTarget), '/classes/class-1/notes');
  });
}

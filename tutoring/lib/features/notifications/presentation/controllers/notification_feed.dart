import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';

/// Pure helpers behind the bell and the notification list.

/// Items the user should see: never their own actions; publishes go to the
/// students of the class, joins go to its tutor. Newest first.
List<AppNotification> visibleNotifications(
  Iterable<AppNotification> items, {
  required String userId,
  required Map<String, StudyClass> classesById,
}) {
  final visible = items
    .where((item) {
      if (item.actorId == userId) return false;
      final studyClass = classesById[item.classId];
      if (studyClass == null) return false;
      final isTutor = studyClass.tutorId == userId;
      return item.type.isForStudents ? !isTutor : isTutor;
    })
    .toList(growable: true)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return visible;
}

/// Notifications newer than the last time the list was opened.
int unreadCount(Iterable<AppNotification> items, DateTime? seenAt) =>
    items.where((item) => isUnread(item, seenAt)).length;

bool isUnread(AppNotification item, DateTime? seenAt) =>
    seenAt == null || item.createdAt.isAfter(seenAt);

/// Where tapping the notification goes.
String notificationRoute(AppNotification item) => switch (item.type) {
  NotificationType.notePublished when item.targetId != null =>
    AppRoutes.noteReader(item.classId, item.targetId!),
  NotificationType.notePublished => AppRoutes.classNotes(item.classId),
  NotificationType.quizPublished => AppRoutes.tuteeQuizzes(item.classId),
  NotificationType.memberJoined => AppRoutes.classDetail(item.classId),
};

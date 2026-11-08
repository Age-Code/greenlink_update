import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/notifications/data/notification_data_providers.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_feed.dart';

export 'package:tutoring/features/notifications/data/notification_data_providers.dart'
    show notificationRepositoryProvider;

final classNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, classId) {
      return ref
          .watch(notificationRepositoryProvider)
          .watchClassNotifications(classId);
    });

final notificationsSeenAtProvider = StreamProvider.family<DateTime?, String>((
  ref,
  userId,
) {
  return ref.watch(notificationRepositoryProvider).watchSeenAt(userId);
});

/// Everything the user should see across their classes, newest first.
/// Empty while the class list or the feeds are still loading.
final myNotificationsProvider = Provider.family<List<AppNotification>, String>((
  ref,
  userId,
) {
  final classes =
      ref.watch(myClassesProvider(userId)).asData?.value ??
      const <StudyClass>[];
  final items = <AppNotification>[
    for (final studyClass in classes)
      ...ref.watch(classNotificationsProvider(studyClass.id)).asData?.value ??
          const <AppNotification>[],
  ];
  return visibleNotifications(
    items,
    userId: userId,
    classesById: {for (final studyClass in classes) studyClass.id: studyClass},
  );
});

final unreadNotificationCountProvider = Provider.family<int, String>((
  ref,
  userId,
) {
  final seenAt = ref.watch(notificationsSeenAtProvider(userId)).asData?.value;
  return unreadCount(ref.watch(myNotificationsProvider(userId)), seenAt);
});

import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  /// Recent notifications of one class, newest first.
  Stream<List<AppNotification>> watchClassNotifications(String classId);

  Future<void> create(AppNotification notification);

  /// When the user last opened the notification list; null before the first.
  Stream<DateTime?> watchSeenAt(String userId);

  Future<void> markSeen({required String userId, required DateTime at});
}

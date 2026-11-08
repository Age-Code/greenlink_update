import 'package:tutoring/features/notifications/data/data_sources/notification_remote_data_source.dart';
import 'package:tutoring/features/notifications/data/dtos/notification_dto.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/domain/repositories/notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  const FirestoreNotificationRepository(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Stream<List<AppNotification>> watchClassNotifications(String classId) =>
      _remoteDataSource
          .watchClassNotifications(classId)
          .map(
            (items) => items
                .map((item) => item.toDomain())
                .whereType<AppNotification>()
                .toList(growable: false),
          );

  @override
  Future<void> create(AppNotification notification) =>
      _remoteDataSource.create(NotificationDto.fromDomain(notification));

  @override
  Stream<DateTime?> watchSeenAt(String userId) =>
      _remoteDataSource.watchSeenAt(userId);

  @override
  Future<void> markSeen({required String userId, required DateTime at}) =>
      _remoteDataSource.markSeen(userId, at);
}

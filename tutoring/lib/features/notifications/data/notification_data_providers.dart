import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/notifications/data/data_sources/notification_remote_data_source.dart';
import 'package:tutoring/features/notifications/data/repositories/firestore_notification_repository.dart';
import 'package:tutoring/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(
    NotificationRemoteDataSource(FirebaseFirestore.instance),
  );
});

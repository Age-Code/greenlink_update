import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.classId,
    required this.type,
    required this.title,
    required this.body,
    required this.actorId,
    required this.actorName,
    required this.targetId,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String type;
  final String title;
  final String body;
  final String actorId;
  final String actorName;
  final String? targetId;
  final DateTime createdAt;

  factory NotificationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return NotificationDto(
      id: snapshot.id,
      classId: data['classId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      targetId: data['targetId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory NotificationDto.fromDomain(AppNotification notification) =>
      NotificationDto(
        id: notification.id,
        classId: notification.classId,
        type: notification.type.firestoreValue,
        title: notification.title,
        body: notification.body,
        actorId: notification.actorId,
        actorName: notification.actorName,
        targetId: notification.targetId,
        createdAt: notification.createdAt,
      );

  Map<String, Object?> toFirestore() => {
    'classId': classId,
    'type': type,
    'title': title,
    'body': body,
    'actorId': actorId,
    'actorName': actorName,
    'targetId': targetId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Null when the stored type is unknown to this app version.
  AppNotification? toDomain() {
    final parsed = NotificationType.fromFirestore(type);
    if (parsed == null) return null;
    return AppNotification(
      id: id,
      classId: classId,
      type: parsed,
      title: title,
      body: body,
      actorId: actorId,
      actorName: actorName,
      targetId: targetId,
      createdAt: createdAt,
    );
  }
}

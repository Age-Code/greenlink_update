import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/core/firebase/firebase_paths.dart';
import 'package:tutoring/features/notifications/data/dtos/notification_dto.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const _recentLimit = 50;

  CollectionReference<Map<String, dynamic>> _notifications(String classId) =>
      _firestore
          .collection(FirebasePaths.classes)
          .doc(classId)
          .collection(FirebasePaths.notifications);

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection(FirebasePaths.users).doc(uid);

  Stream<List<NotificationDto>> watchClassNotifications(String classId) =>
      _notifications(classId)
          .orderBy('createdAt', descending: true)
          .limit(_recentLimit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(NotificationDto.fromFirestore)
                .toList(growable: false),
          );

  Future<void> create(NotificationDto dto) =>
      _notifications(dto.classId).doc().set(dto.toFirestore());

  Stream<DateTime?> watchSeenAt(String uid) => _user(uid).snapshots().map(
    (snapshot) =>
        (snapshot.data()?['notificationsSeenAt'] as Timestamp?)?.toDate(),
  );

  Future<void> markSeen(String uid, DateTime at) => _user(uid).set({
    'notificationsSeenAt': Timestamp.fromDate(at),
  }, SetOptions(merge: true));
}

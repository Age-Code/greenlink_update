/// In-app notification stored under `classes/{classId}/notifications`.
enum NotificationType {
  notePublished('notePublished'),
  quizPublished('quizPublished'),
  memberJoined('memberJoined');

  const NotificationType(this.firestoreValue);

  final String firestoreValue;

  static NotificationType? fromFirestore(String? value) {
    for (final type in values) {
      if (type.firestoreValue == value) return type;
    }
    return null;
  }

  /// Students receive publishes; the class tutor receives joins.
  bool get isForStudents => this != NotificationType.memberJoined;
}

class AppNotification {
  const AppNotification({
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
  final NotificationType type;
  final String title;
  final String body;

  /// Who caused it (the tutor who published, the student who joined).
  final String actorId;
  final String actorName;

  /// noteId / quizId for publishes, the member uid for joins.
  final String? targetId;
  final DateTime createdAt;
}

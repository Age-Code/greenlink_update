import 'package:tutoring/features/auth/domain/entities/user_role.dart';

/// One row of `classes/{classId}/members`. [name] is a display snapshot
/// written when the member joins, so tutors can label students without
/// reading their private `users/{uid}` document.
class ClassMember {
  const ClassMember({
    required this.uid,
    required this.role,
    required this.name,
    required this.joinedAt,
  });

  final String uid;
  final UserRole? role;
  final String? name;
  final DateTime? joinedAt;

  bool get isTutor => role == UserRole.tutor;

  /// Name to show; falls back to a short id for members who joined before
  /// names were stored.
  String get displayName {
    final value = name?.trim() ?? '';
    if (value.isNotEmpty) return value;
    return '학생 ${uid.length <= 4 ? uid : uid.substring(0, 4)}';
  }
}

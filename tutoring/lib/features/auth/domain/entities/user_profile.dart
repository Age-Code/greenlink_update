import 'package:tutoring/features/auth/domain/entities/user_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.profileImageUrl,
    required this.createdAt,
  });

  final String uid;
  final String? email;
  final String name;
  final UserRole? role;
  final String? profileImageUrl;
  final DateTime createdAt;
}

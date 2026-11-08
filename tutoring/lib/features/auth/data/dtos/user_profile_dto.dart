import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';

class UserProfileDto {
  const UserProfileDto({
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
  final String? role;
  final String? profileImageUrl;
  final DateTime createdAt;

  factory UserProfileDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserProfileDto(
      uid: snapshot.id,
      email: data['email'] as String?,
      name: data['name'] as String? ?? '',
      role: data['role'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toFirestore() => {
    'email': email,
    'name': name,
    'role': role,
    'profileImageUrl': profileImageUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserProfile toDomain() => UserProfile(
    uid: uid,
    email: email,
    name: name,
    role: UserRole.fromFirestore(role),
    profileImageUrl: profileImageUrl,
    createdAt: createdAt,
  );
}

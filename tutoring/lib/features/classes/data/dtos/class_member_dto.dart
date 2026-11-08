import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/classes/domain/entities/class_member.dart';

class ClassMemberDto {
  const ClassMemberDto({
    required this.uid,
    required this.role,
    required this.name,
    required this.joinedAt,
  });

  final String uid;
  final String? role;
  final String? name;
  final DateTime? joinedAt;

  factory ClassMemberDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ClassMemberDto(
      uid: data['uid'] as String? ?? document.id,
      role: data['role'] as String?,
      name: data['name'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  ClassMember toDomain() => ClassMember(
    uid: uid,
    role: UserRole.fromFirestore(role),
    name: name,
    joinedAt: joinedAt,
  );
}

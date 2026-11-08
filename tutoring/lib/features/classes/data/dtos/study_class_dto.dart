import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';

/// Older documents still carry `progress` and `recentTopic`; both were never
/// updated after creation and are ignored now.
class StudyClassDto {
  const StudyClassDto({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.tutorId,
    required this.tutorName,
    required this.inviteCode,
    required this.memberCount,
    required this.noteCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String tutorId;
  final String tutorName;
  final String inviteCode;
  final int memberCount;
  final int noteCount;
  final DateTime createdAt;

  factory StudyClassDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return StudyClassDto.fromMap(snapshot.id, data);
  }

  factory StudyClassDto.fromMap(String id, Map<String, dynamic> data) {
    return StudyClassDto(
      id: id,
      title: data['title'] as String? ?? '이름 없는 클래스',
      category: data['category'] as String? ?? 'STUDY',
      description: data['description'] as String? ?? '',
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 1,
      noteCount: (data['noteCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toFirestore() => {
    'title': title,
    'category': category,
    'description': description,
    'tutorId': tutorId,
    'tutorName': tutorName,
    'inviteCode': inviteCode,
    'memberCount': memberCount,
    'noteCount': noteCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, Object?> toMembershipFirestore(String role) => {
    'classId': id,
    'role': role,
    ...toFirestore(),
    'joinedAt': FieldValue.serverTimestamp(),
  };

  StudyClass toDomain() => StudyClass(
    id: id,
    title: title,
    category: category,
    description: description,
    tutorId: tutorId,
    tutorName: tutorName,
    inviteCode: inviteCode,
    memberCount: memberCount,
    noteCount: noteCount,
    createdAt: createdAt,
  );
}

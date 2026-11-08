import 'package:tutoring/features/classes/domain/entities/class_member.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';

abstract interface class ClassRepository {
  Stream<List<StudyClass>> watchMyClasses(String userId);
  Stream<StudyClass?> watchClass(String classId);

  /// Tutor and students of a class, oldest member first.
  Stream<List<ClassMember>> watchMembers(String classId);

  Future<StudyClass> createClass({
    required String userId,
    required String tutorName,
    required String title,
    required String description,
  });

  Future<StudyClass> joinClass({
    required String userId,
    required String userName,
    required String inviteCode,
  });

  /// One-shot list of the classes the user belongs to.
  Future<List<StudyClass>> getMyClasses(String userId);

  /// Whether the user is the tutor of at least one class.
  Future<bool> ownsAnyClass(String userId);

  /// Removes the user from a class: member document, membership document and
  /// the class member count change together.
  Future<void> leaveClass({required String userId, required String classId});

  /// Deletes a class owned by [userId], including its shared class content and
  /// every member's class-membership index.
  Future<void> deleteClass({required String userId, required String classId});

  /// Rewrites the name snapshot kept in every class the user belongs to.
  Future<void> updateMemberName({required String userId, required String name});
}

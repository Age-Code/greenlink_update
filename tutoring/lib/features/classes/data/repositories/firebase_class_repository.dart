import 'package:tutoring/features/classes/data/data_sources/class_remote_data_source.dart';
import 'package:tutoring/features/classes/domain/entities/class_member.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/domain/repositories/class_repository.dart';

class FirebaseClassRepository implements ClassRepository {
  const FirebaseClassRepository(this._remoteDataSource);

  final ClassRemoteDataSource _remoteDataSource;

  @override
  Stream<List<StudyClass>> watchMyClasses(String userId) => _remoteDataSource
      .watchMyClasses(userId)
      .map(
        (items) => items.map((item) => item.toDomain()).toList(growable: false),
      );

  @override
  Stream<StudyClass?> watchClass(String classId) =>
      _remoteDataSource.watchClass(classId).map((item) => item?.toDomain());

  @override
  Stream<List<ClassMember>> watchMembers(String classId) => _remoteDataSource
      .watchMembers(classId)
      .map(
        (items) => items.map((item) => item.toDomain()).toList(growable: false),
      );

  @override
  Future<StudyClass> createClass({
    required String userId,
    required String tutorName,
    required String title,
    required String description,
  }) async =>
      (await _remoteDataSource.createClass(
        userId: userId,
        tutorName: tutorName,
        title: title,
        description: description,
      )).toDomain();

  @override
  Future<StudyClass> joinClass({
    required String userId,
    required String userName,
    required String inviteCode,
  }) async =>
      (await _remoteDataSource.joinClass(
        userId: userId,
        userName: userName,
        inviteCode: inviteCode,
      )).toDomain();

  @override
  Future<List<StudyClass>> getMyClasses(String userId) async =>
      (await _remoteDataSource.getMyClasses(
        userId,
      )).map((item) => item.toDomain()).toList(growable: false);

  @override
  Future<bool> ownsAnyClass(String userId) =>
      _remoteDataSource.ownsAnyClass(userId);

  @override
  Future<void> leaveClass({required String userId, required String classId}) =>
      _remoteDataSource.leaveClass(userId: userId, classId: classId);

  @override
  Future<void> deleteClass({required String userId, required String classId}) =>
      _remoteDataSource.deleteClass(userId: userId, classId: classId);

  @override
  Future<void> updateMemberName({
    required String userId,
    required String name,
  }) => _remoteDataSource.updateMemberName(userId: userId, name: name);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/classes/data/class_data_providers.dart';
import 'package:tutoring/features/classes/domain/entities/class_member.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_writer.dart';

export 'package:tutoring/features/classes/data/class_data_providers.dart'
    show classRepositoryProvider;

final myClassesProvider = StreamProvider.family<List<StudyClass>, String>((
  ref,
  userId,
) {
  return ref.watch(classRepositoryProvider).watchMyClasses(userId);
});

final studyClassProvider = StreamProvider.family<StudyClass?, String>((
  ref,
  classId,
) {
  return ref.watch(classRepositoryProvider).watchClass(classId);
});

final classMembersProvider = StreamProvider.family<List<ClassMember>, String>((
  ref,
  classId,
) {
  return ref.watch(classRepositoryProvider).watchMembers(classId);
});

final classActionControllerProvider =
    AsyncNotifierProvider<ClassActionController, void>(
      ClassActionController.new,
    );

class ClassActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<StudyClass?> createClass({
    required String userId,
    required String tutorName,
    required String title,
    required String description,
  }) async {
    state = const AsyncLoading();
    StudyClass? created;
    state = await AsyncValue.guard(() async {
      created = await ref
          .read(classRepositoryProvider)
          .createClass(
            userId: userId,
            tutorName: tutorName,
            title: title,
            description: description,
          );
    });
    return created;
  }

  Future<StudyClass?> joinClass({
    required String userId,
    required String userName,
    required String inviteCode,
  }) async {
    state = const AsyncLoading();
    StudyClass? joined;
    state = await AsyncValue.guard(() async {
      joined = await ref
          .read(classRepositoryProvider)
          .joinClass(
            userId: userId,
            userName: userName,
            inviteCode: inviteCode,
          );
    });
    final joinedClass = joined;
    if (joinedClass != null) {
      await ref
          .read(notificationWriterProvider)
          .memberJoined(classId: joinedClass.id, memberName: userName);
    }
    return joined;
  }

  Future<bool> deleteClass({
    required String userId,
    required String classId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(classRepositoryProvider)
          .deleteClass(userId: userId, classId: classId),
    );
    return !state.hasError;
  }
}

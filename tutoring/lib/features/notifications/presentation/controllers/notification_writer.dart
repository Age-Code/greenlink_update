import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_providers.dart';

final notificationWriterProvider = Provider<NotificationWriter>(
  NotificationWriter.new,
);

/// Writes the in-app notifications behind tutor publishes and student joins.
/// Best effort: a failed write never fails the action that caused it.
class NotificationWriter {
  NotificationWriter(this._ref);

  final Ref _ref;

  Future<void> notePublished({
    required String classId,
    required String noteId,
    required String noteTitle,
  }) => _send(
    classId: classId,
    type: NotificationType.notePublished,
    title: '새 노트가 게시됐어요',
    body: noteTitle,
    targetId: noteId,
  );

  Future<void> quizPublished({
    required String classId,
    required String quizId,
    required String quizTitle,
  }) => _send(
    classId: classId,
    type: NotificationType.quizPublished,
    title: '새 퀴즈가 게시됐어요',
    body: quizTitle,
    targetId: quizId,
  );

  Future<void> memberJoined({
    required String classId,
    required String memberName,
  }) async {
    final user = _ref.read(authStateProvider).asData?.value;
    await _send(
      classId: classId,
      type: NotificationType.memberJoined,
      title: '새 학생이 참여했어요',
      body: '$memberName님이 클래스에 들어왔어요.',
      targetId: user?.uid,
      actorName: memberName,
    );
  }

  Future<void> _send({
    required String classId,
    required NotificationType type,
    required String title,
    required String body,
    String? targetId,
    String? actorName,
  }) async {
    final user = _ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final profileName =
        _ref.read(userProfileProvider(user.uid)).asData?.value?.name ?? '';
    try {
      await _ref
          .read(notificationRepositoryProvider)
          .create(
            AppNotification(
              id: '',
              classId: classId,
              type: type,
              title: title,
              body: body,
              actorId: user.uid,
              actorName: actorName ?? profileName,
              targetId: targetId,
              createdAt: DateTime.now(),
            ),
          );
    } catch (_) {
      // The note / quiz / join itself already succeeded.
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/format/relative_time.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_adaptive_sheet.dart';
import 'package:tutoring/features/notifications/domain/entities/app_notification.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_feed.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_providers.dart';

/// Bell list: recent notifications of my classes. Opening it records the
/// time as "seen", which clears the bell badge.
Future<void> showNotificationSheet(
  BuildContext context, {
  required String userId,
}) {
  final router = GoRouter.of(context);
  return showAppSheet<void>(
    context: context,
    builder:
        (_) => NotificationSheet(
          userId: userId,
          onOpen: (location) => router.push(location),
        ),
  );
}

class NotificationSheet extends ConsumerStatefulWidget {
  const NotificationSheet({
    super.key,
    required this.userId,
    required this.onOpen,
  });

  final String userId;

  /// Called with the route location after the sheet has closed.
  final ValueChanged<String> onOpen;

  static Key itemKey(AppNotification item) => Key('notification-${item.id}');

  @override
  ConsumerState<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<NotificationSheet> {
  /// Seen time when the sheet opened, so unread dots do not vanish while
  /// the user is still looking at the list.
  DateTime? _openedWithSeenAt;
  var _captured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
  }

  Future<void> _markSeen() async {
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markSeen(userId: widget.userId, at: DateTime.now());
    } catch (_) {
      // The badge simply stays until the next successful open.
    }
  }

  void _open(AppNotification item) {
    final location = notificationRoute(item);
    Navigator.of(context).pop();
    widget.onOpen(location);
  }

  @override
  Widget build(BuildContext context) {
    final seenAt =
        ref.watch(notificationsSeenAtProvider(widget.userId)).asData?.value;
    if (!_captured) {
      _openedWithSeenAt = seenAt;
      _captured = true;
    }
    final items = ref.watch(myNotificationsProvider(widget.userId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '알림',
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '내 클래스의 새 노트 · 퀴즈 · 참여 소식이에요.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 32,
                    color: AppColors.textFaint,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '새 알림이 없어요.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder:
                    (_, _) =>
                        const Divider(height: 1, color: AppColors.homeDivider),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationRow(
                    key: NotificationSheet.itemKey(item),
                    item: item,
                    unread: isUnread(item, _openedWithSeenAt),
                    onTap: () => _open(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final AppNotification item;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = switch (item.type) {
      NotificationType.notePublished => (
        Icons.description_outlined,
        AppColors.homeCream,
        AppColors.homeBrown,
      ),
      NotificationType.quizPublished => (
        Icons.quiz_outlined,
        AppColors.homeSage,
        AppColors.homeSageDark,
      ),
      NotificationType.memberJoined => (
        Icons.person_add_alt_1_outlined,
        AppColors.homePeach,
        AppColors.coralDark,
      ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.homeInk,
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTimeLabel(item.createdAt),
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

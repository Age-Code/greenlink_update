import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_adaptive_sheet.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';

/// Class summary: name, description, tutor, members, invite code, and delete.
Future<void> showClassInfoSheet(
  BuildContext context,
  StudyClass studyClass,
) async {
  final deleted = await showAppSheet<bool>(
    context: context,
    builder: (context) => ClassInfoSheet(studyClass: studyClass),
  );
  if (deleted == true && context.mounted) context.go(AppRoutes.home);
}

class ClassInfoSheet extends ConsumerStatefulWidget {
  const ClassInfoSheet({super.key, required this.studyClass});

  final StudyClass studyClass;

  @override
  ConsumerState<ClassInfoSheet> createState() => _ClassInfoSheetState();
}

class _ClassInfoSheetState extends ConsumerState<ClassInfoSheet> {
  var _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final studyClass = widget.studyClass;
    final user = ref.watch(authStateProvider).asData?.value;
    final canDelete = user?.uid == studyClass.tutorId;
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
            '클래스 정보',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            studyClass.title,
            style: const TextStyle(
              color: AppColors.homeInk,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            studyClass.description.isEmpty
                ? '함께 배우고 기록하는 스터디 클래스입니다.'
                : studyClass.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(label: '튜터', value: studyClass.tutorName),
          const Divider(height: AppSpacing.lg, color: AppColors.homeDivider),
          _InfoRow(label: '참여 인원', value: '${studyClass.memberCount}명'),
          const Divider(height: AppSpacing.lg, color: AppColors.homeDivider),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '참여 코드',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              SelectableText(
                studyClass.inviteCode,
                style: const TextStyle(
                  color: AppColors.homeBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                tooltip: '참여 코드 공유',
                onPressed:
                    () => Share.share(
                      '${studyClass.title} 클래스에 참여해요!\n참여 코드: ${studyClass.inviteCode}',
                    ),
                icon: const Icon(Icons.ios_share, size: 18),
              ),
              IconButton(
                tooltip: '참여 코드 복사',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: studyClass.inviteCode),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('참여 코드를 복사했어요.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (canDelete) ...[
            OutlinedButton.icon(
              onPressed:
                  _isDeleting ? null : () => _deleteClass(context, user!.uid),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coralDark,
                side: const BorderSide(color: AppColors.coralDark),
                minimumSize: const Size(0, AppLayout.minTouchHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon:
                  _isDeleting
                      ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.delete_outline, size: 18),
              label: Text(_isDeleting ? '삭제 중...' : '클래스 삭제'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FilledButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: AppColors.surface,
              minimumSize: const Size(0, AppLayout.minTouchHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('클래스를 삭제할까요?'),
            content: Text(
              '${widget.studyClass.title}의 노트와 퀴즈가 모두 삭제되며 되돌릴 수 없어요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coralDark,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    final success = await ref
        .read(classActionControllerProvider.notifier)
        .deleteClass(userId: userId, classId: widget.studyClass.id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('클래스를 삭제하지 못했어요. 다시 시도해주세요.')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.homeInk,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

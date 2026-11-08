import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/widgets/app_adaptive_sheet.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';

/// Create or join a class. Full-width sheet on mobile, inset sheet on
/// tablet, centered dialog on desktop (see [showAppSheet]).
Future<void> showClassAddSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const _ClassAddSheet(),
  );
}

class _ClassAddSheet extends ConsumerStatefulWidget {
  const _ClassAddSheet();

  @override
  ConsumerState<_ClassAddSheet> createState() => _ClassAddSheetState();
}

class _ClassAddSheetState extends ConsumerState<_ClassAddSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  var _isCreateMode = true;
  StudyClass? _createdClass;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(classActionControllerProvider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 12, 17),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '클래스 추가',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '새로운 클래스를 만들거나 기존 클래스에 참여할 수 있어요.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.softGray),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  _ModeSelector(
                    isCreateMode: _isCreateMode,
                    onChanged:
                        (value) => setState(() {
                          _isCreateMode = value;
                          _createdClass = null;
                        }),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child:
                        _isCreateMode
                            ? _CreateForm(
                              key: const ValueKey('create'),
                              titleController: _titleController,
                              descriptionController: _descriptionController,
                              isLoading: action.isLoading,
                              createdClass: _createdClass,
                              onSubmit: _createClass,
                            )
                            : _JoinForm(
                              key: const ValueKey('join'),
                              codeController: _codeController,
                              isLoading: action.isLoading,
                              onSubmit: _joinClass,
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

  Future<void> _createClass() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('클래스 이름을 입력해 주세요.');
      return;
    }
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _showError('다시 로그인해 주세요.');
      return;
    }
    final tutorName = user.email?.split('@').first ?? 'Tutor';
    final created = await ref
        .read(classActionControllerProvider.notifier)
        .createClass(
          userId: user.uid,
          tutorName: tutorName,
          title: title,
          description: _descriptionController.text,
        );
    if (!mounted) return;
    if (created == null) {
      _showError('클래스를 만들지 못했어요.');
      return;
    }
    setState(() => _createdClass = created);
  }

  Future<void> _joinClass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError('참여 코드를 입력해 주세요.');
      return;
    }
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _showError('다시 로그인해 주세요.');
      return;
    }
    final profileName =
        ref.read(userProfileProvider(user.uid)).asData?.value?.name.trim() ??
        '';
    final joined = await ref
        .read(classActionControllerProvider.notifier)
        .joinClass(
          userId: user.uid,
          userName:
              profileName.isNotEmpty
                  ? profileName
                  : user.email?.split('@').first ?? '학생',
          inviteCode: code,
        );
    if (!mounted) return;
    if (joined == null) {
      _showError('참여 코드를 확인해 주세요.');
      return;
    }
    Navigator.pop(context);
    context.push(AppRoutes.classDetail(joined.id));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.isCreateMode, required this.onChanged});

  final bool isCreateMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: '새 클래스 만들기',
              icon: Icons.add_circle_outline,
              selected: isCreateMode,
              onPressed: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeButton(
              label: '클래스 참여하기',
              icon: Icons.group_add_outlined,
              selected: !isCreateMode,
              onPressed: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.coralSoft : Colors.transparent,
          border: selected ? Border.all(color: const Color(0xFFFDE6D9)) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.coralDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selected ? AppColors.coralDark : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateForm extends StatelessWidget {
  const _CreateForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.isLoading,
    required this.createdClass,
    required this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isLoading;
  final StudyClass? createdClass;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetField(
          label: '클래스 이름 *',
          hint: '예: Python Study',
          controller: titleController,
        ),
        const SizedBox(height: 16),
        _SheetField(
          label: '한 줄 설명',
          hint: '어떤 내용을 함께 공부하나요?',
          controller: descriptionController,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: isLoading ? null : onSubmit,
          style: _primaryButtonStyle,
          icon:
              isLoading
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.library_add_outlined, size: 19),
          label: Text(isLoading ? '만드는 중...' : '클래스 만들기'),
        ),
        if (createdClass != null) ...[
          const SizedBox(height: 20),
          _InviteCodeCard(studyClass: createdClass!),
        ],
      ],
    );
  }
}

class _JoinForm extends StatelessWidget {
  const _JoinForm({
    super.key,
    required this.codeController,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController codeController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetField(
          label: '참여 코드',
          hint: 'STUDY-ABC123',
          controller: codeController,
          capitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        const Text(
          '튜터에게 받은 코드를 입력하면 공용 노트와 퀴즈를 함께 볼 수 있어요.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: isLoading ? null : onSubmit,
          style: _primaryButtonStyle,
          icon:
              isLoading
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.arrow_forward, size: 19),
          label: Text(isLoading ? '참여하는 중...' : '이 클래스에 참여하기'),
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
    this.capitalization = TextCapitalization.sentences,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          textCapitalization: capitalization,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.studyClass});

  final StudyClass studyClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.key_outlined, color: AppColors.homeBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참여 코드: ${studyClass.inviteCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '이 코드를 함께 공부할 사람에게 공유하세요.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.classDetail(studyClass.id));
            },
            child: const Text('클래스 열기'),
          ),
        ],
      ),
    );
  }
}

final ButtonStyle _primaryButtonStyle = FilledButton.styleFrom(
  backgroundColor: AppColors.coral,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(54),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
);

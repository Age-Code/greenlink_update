import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/auth/domain/entities/auth_user.dart';
import 'package:tutoring/features/auth/domain/entities/user_profile.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/home/presentation/controllers/home_summary.dart';
import 'package:tutoring/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/profile/domain/account_reauth.dart';
import 'package:tutoring/features/profile/presentation/content/policy_texts.dart';
import 'package:tutoring/features/profile/presentation/controllers/profile_controller.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';

/// 마이: profile, learning summary, settings, policies and account actions.
/// Composed from the Page 2 card language; Figma has no frame for it.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  static const deleteConfirmFieldKey = Key('delete-confirm-field');
  static const deletePasswordFieldKey = Key('delete-password-field');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final profile = ref.watch(userProfileProvider(user.uid));
    final isDesktop = context.screenType == ScreenType.desktop;

    ref.listen(profileControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = ref
              .read(profileControllerProvider.notifier)
              .messageFor(error);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return AppResponsiveScaffold(
      leading: IconButton(
        tooltip: '홈으로',
        onPressed: () => context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('마이'),
      body: profile.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
        error:
            (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(userProfileProvider(user.uid)),
                child: const Text('다시 불러오기'),
              ),
            ),
        data: (value) => _MyBody(user: user, profile: value),
      ),
      bottomNavigationBar:
          isDesktop ? null : const HomeBottomNav(selected: HomeTab.my),
    );
  }
}

String _roleLabel(UserRole role) => role == UserRole.tutor ? '튜터' : '튜티';

class _MyBody extends ConsumerWidget {
  const _MyBody({required this.user, required this.profile});

  final AuthUser user;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = profile?.role;
    final profileName = profile?.name.trim() ?? '';
    final name =
        profileName.isNotEmpty
            ? profileName
            : (user.email?.split('@').first ?? '학습자');
    final busy = ref.watch(profileControllerProvider).isLoading;
    final email = user.email;

    return AppPageBody(
      children: [
        _ProfileCard(
          name: name,
          email: email,
          role: role,
          joinedAt: profile?.createdAt,
          imageUrl: profile?.profileImageUrl,
        ),
        const SizedBox(height: 20),
        _LearningSummaryCard(userId: user.uid, role: role),
        const SizedBox(height: 20),
        _SectionCard(
          title: '설정',
          children: [
            _SettingTile(
              icon: Icons.badge_outlined,
              title: '이름 수정',
              subtitle: name,
              enabled: !busy,
              onTap: () => _editName(context, ref, user.uid, name),
            ),
            _SettingTile(
              icon: Icons.swap_horiz,
              title: '역할 변경',
              subtitle:
                  role == null ? '아직 역할을 고르지 않았어요' : '현재 ${_roleLabel(role)}',
              enabled: !busy,
              onTap: () => _changeRole(context, ref, role),
            ),
            if (user.hasPasswordProvider && email != null)
              _SettingTile(
                icon: Icons.lock_reset,
                title: '비밀번호 재설정 메일 보내기',
                subtitle: email,
                enabled: !busy,
                onTap: () => _sendPasswordReset(context, ref, email),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: '개인정보 및 약관',
          children: [
            for (final kind in PolicyKind.values)
              _SettingTile(
                icon: switch (kind) {
                  PolicyKind.privacy => Icons.privacy_tip_outlined,
                  PolicyKind.terms => Icons.description_outlined,
                  PolicyKind.data => Icons.inventory_2_outlined,
                },
                title: kind.title,
                onTap: () => context.push(AppRoutes.policy(kind.slug)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: '계정',
          children: [
            _SettingTile(
              icon: Icons.logout,
              title: '로그아웃',
              enabled: !busy,
              onTap: () => _signOut(context, ref),
            ),
            _SettingTile(
              icon: Icons.person_remove_outlined,
              title: '회원 탈퇴',
              subtitle: '프로필과 모든 학습 기록이 삭제돼요',
              destructive: true,
              enabled: !busy,
              onTap: () => _deleteAccount(context, ref, user),
            ),
          ],
        ),
        if (busy) ...[
          const SizedBox(height: 24),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.coral,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Actions

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _editName(
  BuildContext context,
  WidgetRef ref,
  String uid,
  String current,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(initial: current),
  );
  if (name == null || name.trim().isEmpty || !context.mounted) return;
  final ok = await ref
      .read(profileControllerProvider.notifier)
      .updateName(uid: uid, name: name);
  if (ok && context.mounted) _snack(context, '이름을 바꿨어요.');
}

Future<void> _changeRole(
  BuildContext context,
  WidgetRef ref,
  UserRole? current,
) async {
  final target = current == UserRole.tutor ? UserRole.tutor : UserRole.tutee;
  final next = target == UserRole.tutor ? UserRole.tutee : UserRole.tutor;
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('${_roleLabel(next)}로 바꿀까요?'),
          content: Text(
            next == UserRole.tutor
                ? '튜터가 되면 클래스를 만들고 노트와 퀴즈를 게시할 수 있어요. '
                    '지금 참여 중인 클래스는 그대로 유지돼요.'
                : '튜티가 되면 내가 만든 클래스에서 튜터 화면 대신 학생 화면이 보여요. '
                    '클래스와 자료는 그대로 남아요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('바꾸기'),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await ref
      .read(profileControllerProvider.notifier)
      .changeRole(next);
  if (!context.mounted) return;
  _snack(context, ok ? '${_roleLabel(next)}로 바꿨어요.' : '역할을 바꾸지 못했어요.');
}

Future<void> _sendPasswordReset(
  BuildContext context,
  WidgetRef ref,
  String email,
) async {
  final ok = await ref
      .read(profileControllerProvider.notifier)
      .sendPasswordReset(email);
  if (ok && context.mounted) {
    _snack(context, '$email 로 재설정 메일을 보냈어요. 받은편지함을 확인해 주세요.');
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final ok = await ref.read(profileControllerProvider.notifier).signOut();
  if (ok && context.mounted) context.go(AppRoutes.login);
}

Future<void> _deleteAccount(
  BuildContext context,
  WidgetRef ref,
  AuthUser user,
) async {
  final reauth = await showDialog<AccountReauth>(
    context: context,
    builder: (_) => _DeleteAccountDialog(user: user),
  );
  if (reauth == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await ref
      .read(profileControllerProvider.notifier)
      .deleteAccount(uid: user.uid, reauth: reauth);
  if (!ok || !context.mounted) return;
  context.go(AppRoutes.onboarding);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('탈퇴가 완료됐어요. 그동안 고마웠어요.')));
}

// ---------------------------------------------------------------------------
// Cards

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    required this.imageUrl,
  });

  final String name;
  final String? email;
  final UserRole? role;
  final DateTime? joinedAt;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final joined = joinedAt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.homeDivider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.homePeach,
            backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
            child:
                imageUrl == null
                    ? Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.homeBrown,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.homeInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    _RoleChip(role: role),
                  ],
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (joined != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '가입 ${joined.year}.'
                    '${joined.month.toString().padLeft(2, '0')}.'
                    '${joined.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (role) {
      UserRole.tutor => (AppColors.coralSoft, AppColors.coralDark, '튜터'),
      UserRole.tutee => (AppColors.homeSage, AppColors.homeSageDark, '튜티'),
      null => (AppColors.softGray, AppColors.textSecondary, '역할 미선택'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Three live numbers: students see classes / quizzes / pending reviews,
/// tutors see classes / notes / students.
class _LearningSummaryCard extends ConsumerWidget {
  const _LearningSummaryCard({required this.userId, required this.role});

  final String userId;
  final UserRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(myClassesProvider(userId)).asData?.value;
    final List<(String, int?, String)> stats;
    if (role == UserRole.tutor) {
      final owned = classes
          ?.where((studyClass) => studyClass.tutorId == userId)
          .toList(growable: false);
      var notes = 0;
      var notesLoading = false;
      var students = 0;
      for (final studyClass in owned ?? const <StudyClass>[]) {
        final value = ref.watch(allNotesProvider(studyClass.id));
        if (value.hasValue) {
          notes += value.value!.length;
        } else {
          notesLoading = true;
        }
        students += math.max(0, studyClass.memberCount - 1);
      }
      stats = [
        ('운영 클래스', owned?.length, '개'),
        ('작성 노트', notesLoading || owned == null ? null : notes, '개'),
        ('학생', owned == null ? null : students, '명'),
      ];
    } else {
      final attempts = ref.watch(quizAttemptsProvider(userId)).asData?.value;
      final reviews = ref.watch(myReviewsProvider(userId)).asData?.value;
      stats = [
        ('참여 클래스', classes?.length, '개'),
        ('푼 퀴즈', attempts?.length, '번'),
        ('남은 복습', reviews == null ? null : pendingReviewCount(reviews), '개'),
      ];
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.homeDivider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0)
              const SizedBox(
                height: 36,
                child: VerticalDivider(color: AppColors.homeDivider),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[index].$2 == null
                        ? '–'
                        : '${stats[index].$2}${stats[index].$3}',
                    style: const TextStyle(
                      color: AppColors.homeInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[index].$1,
                    style: const TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
      ),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.homeDivider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, color: AppColors.homeDivider),
              children[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.coralDark : AppColors.homeBrown;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      destructive ? AppColors.coralSoft : AppColors.homeCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                            destructive
                                ? AppColors.coralDark
                                : AppColors.homeInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.homeMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('이름 수정'),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value);
        },
        decoration: const InputDecoration(
          hintText: '클래스에서 보일 이름',
          border: OutlineInputBorder(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed:
            _controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _controller.text),
        child: const Text('저장'),
      ),
    ],
  );
}

/// Explains what is removed, asks the user to type 탈퇴, and collects the
/// password for email accounts. Google accounts confirm through a popup
/// afterwards. Returns the reauthentication to perform.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.user});

  final AuthUser user;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirm = TextEditingController();
  final _password = TextEditingController();

  bool get _usesPassword => widget.user.hasPasswordProvider;

  bool get _canSubmit =>
      _confirm.text.trim() == '탈퇴' &&
      (!_usesPassword || _password.text.isNotEmpty);

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('정말 탈퇴할까요?'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '탈퇴하면 아래 내용이 바로 삭제되고 복구할 수 없어요.',
              style: TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
            const SizedBox(height: 10),
            for (final line in const [
              '프로필(이름, 이메일, 역할)',
              '참여 중인 클래스에서 나가기',
              '노트에 남긴 메모 · 강조 · 북마크 · 필기',
              '퀴즈와 Quick Check 풀이 기록',
              '복습(오답 노트) 항목',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '•  $line',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              key: MyScreen.deleteConfirmFieldKey,
              controller: _confirm,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "확인을 위해 '탈퇴'를 입력하세요",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_usesPassword)
              TextField(
                key: MyScreen.deletePasswordFieldKey,
                controller: _password,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
              )
            else
              const Text(
                '본인 확인을 위해 Google 로그인 창이 한 번 더 열려요.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed:
            _canSubmit
                ? () => Navigator.pop<AccountReauth>(
                  context,
                  _usesPassword
                      ? PasswordReauth(_password.text)
                      : const GoogleReauth(),
                )
                : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coralDark,
          foregroundColor: Colors.white,
        ),
        child: const Text('탈퇴하기'),
      ),
    ],
  );
}

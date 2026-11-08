import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_text_field.dart';
import 'package:tutoring/core/widgets/primary_button.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutoring/features/auth/presentation/widgets/adaptive_auth_frame.dart';
import 'package:tutoring/features/auth/presentation/widgets/social_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authControllerProvider.notifier).messageFor(error),
            ),
          ),
        ),
      );
    });

    return AdaptiveAuthFrame(
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  AppSpacing.xxl,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    icon: const Icon(Icons.chevron_left, size: 28),
                  ),
                ),
                const SizedBox(height: 14),
                const _StudyTogetherLogo(),
                const SizedBox(height: 20),
                Text(
                  'Tugether',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '함께, 더 깊이 공부하는',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 30),
                _AuthSegmentedControl(
                  onRegister: () => context.push(AppRoutes.register),
                ),
                const SizedBox(height: 30),
                AppTextField(
                  controller: _emailController,
                  hintText: '이메일을 입력하세요',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  hintText: '비밀번호를 입력하세요',
                  icon: Icons.password_outlined,
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: '로그인',
                  isLoading: authState.isLoading,
                  onPressed: _canSubmit ? _submitEmail : null,
                ),
                const SizedBox(height: 24),
                const _Divider(),
                const SizedBox(height: 24),
                SocialSignInButton(
                  provider: 'G',
                  label: 'Google로 시작하기',
                  providerColor: const Color(0xFF4285F4),
                  onPressed: authState.isLoading
                      ? null
                      : () => _submitSocial(
                          ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle,
                        ),
                ),
                const SizedBox(height: 12),
                SocialSignInButton(
                  provider: 'A',
                  label: 'Apple로 시작하기',
                  providerColor: AppColors.textPrimary,
                  onPressed: authState.isLoading
                      ? null
                      : () => _submitSocial(
                          ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple,
                        ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: authState.isLoading ? null : _resetPassword,
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 6;

  Future<void> _submitEmail() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) context.go(AppRoutes.roleSelection);
  }

  Future<void> _submitSocial(Future<bool> Function() action) async {
    final success = await action();
    if (success && mounted) context.go(AppRoutes.roleSelection);
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 이메일을 입력해 주세요.')),
      );
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 재설정 메일을 보냈어요.')),
      );
    }
  }
}

class _StudyTogetherLogo extends StatelessWidget {
  const _StudyTogetherLogo();
  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    height: 92,
    decoration: BoxDecoration(
      color: AppColors.coralSoft,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 20,
          top: 20,
          child: SvgPicture.asset('assets/images/auth/leaf_left.svg', width: 36),
        ),
        Positioned(
          right: 18,
          top: 17,
          child: SvgPicture.asset('assets/images/auth/leaf_right.svg', width: 36),
        ),
        Positioned(
          top: 33,
          child: Container(width: 4, height: 25, color: AppColors.coralDark),
        ),
      ],
    ),
  );
}

class _AuthSegmentedControl extends StatelessWidget {
  const _AuthSegmentedControl({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.softGray,
      borderRadius: BorderRadius.circular(AppRadius.segment),
    ),
    child: Row(
      children: [
        _Segment(
          label: '로그인',
          selected: true,
          onTap: () {},
        ),
        _Segment(
          label: '회원가입',
          selected: false,
          onTap: onRegister,
        ),
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('또는', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
      ),
      Expanded(child: Divider(color: AppColors.border)),
    ],
  );
}

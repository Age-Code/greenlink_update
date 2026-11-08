import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutoring/features/auth/presentation/widgets/adaptive_auth_frame.dart';
import 'package:tutoring/features/auth/presentation/widgets/social_sign_in_button.dart';

class StudyTogetherRegisterScreen extends ConsumerWidget {
  const StudyTogetherRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveAuthFrame(
      child: RegisterScreen(
        showAuthActionSwitch: false,
        actions: [
          AuthStateChangeAction((context, state) {
            if (state is UserCreated || state is SignedIn) {
              context.go(AppRoutes.roleSelection);
            }
          }),
        ],
        headerBuilder: (context, constraints, shrinkOffset) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.chevron_left, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  '회원가입',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Google 또는 이메일로 계정을 만들어 주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
        subtitleBuilder: (context, action) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Tugether 시작하기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        footerBuilder: (context, action) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(authControllerProvider);
              ref.listen(authControllerProvider, (_, next) {
                next.whenOrNull(
                  error: (error, _) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref
                            .read(authControllerProvider.notifier)
                            .messageFor(error),
                      ),
                    ),
                  ),
                );
              });
              return Column(
                children: [
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SocialSignInButton(
                    provider: 'G',
                    label: state.isLoading
                        ? 'Google 연결 중...'
                        : 'Google로 회원가입',
                    providerColor: const Color(0xFF4285F4),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final success = await ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle();
                            if (success && context.mounted) {
                              context.go(AppRoutes.roleSelection);
                            }
                          },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

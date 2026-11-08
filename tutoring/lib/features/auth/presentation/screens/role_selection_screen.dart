import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/role_controller.dart';
import 'package:tutoring/features/auth/presentation/widgets/adaptive_auth_frame.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleControllerProvider);
    ref.listen(roleControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('역할을 저장하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    });

    Future<void> select(UserRole role) async {
      final saved = await ref.read(roleControllerProvider.notifier).selectRole(role);
      if (saved && context.mounted) context.go(AppRoutes.home);
    }

    return AdaptiveAuthFrame(
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: state.isLoading ? null : () => context.go(AppRoutes.login),
                    icon: const Icon(Icons.chevron_left, size: 28),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: state.isLoading ? null : () => context.go(AppRoutes.home),
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '어떤 역할로\n시작하시나요?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '지금은 튜터로 시작해도, 언제든 변경할 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                title: '튜터로 시작하기',
                lines: const ['나만의 학습 노트를 만들고', '튜티와 함께 공부해요.'],
                backgroundColor: AppColors.coralSoft,
                asset: 'assets/images/auth/tutor_avatar.svg',
                onTap: state.isLoading ? null : () => select(UserRole.tutor),
              ),
              const SizedBox(height: 20),
              _RoleCard(
                title: '튜티로 시작하기',
                lines: const ['튜터의 노트를 통해', '체계적으로 학습해요.'],
                backgroundColor: AppColors.sage,
                asset: 'assets/images/auth/tutee_avatar.svg',
                onTap: state.isLoading ? null : () => select(UserRole.tutee),
              ),
              const SizedBox(height: 28),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.border,
                      child: Icon(Icons.swap_horiz, size: 17, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: const [
                          TextSpan(
                            text: '나중에 마이페이지에서\n',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextSpan(text: '역할을 변경할 수 있어요.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.lines,
    required this.backgroundColor,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final List<String> lines;
  final Color backgroundColor;
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(AppRadius.card),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 190,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 18),
          child: Row(
            children: [
              SvgPicture.asset(asset, width: 100, height: 132),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 7),
                    Text(lines.join('\n'), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.arrow_forward, color: AppColors.coralDark, size: 18),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

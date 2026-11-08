import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/primary_button.dart';
import 'package:tutoring/features/auth/presentation/widgets/adaptive_auth_frame.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveAuthFrame(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xxl,
              AppSpacing.screen,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '함께 공부하고,\n더 깊이 이해하는\n'),
                      TextSpan(
                        text: '나만의 튜터링 공간',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.coralDark),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '튜터의 노트와 나의 필기가 만나\n더 효과적인 학습이 시작돼요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _LearningIllustration(),
                    ),
                  ),
                ),
                const _FeatureRow(
                  badge: 'N',
                  title: '튜터가 만든 체계적인 학습 노트',
                  subtitle: '개념부터 문제까지 한 곳에서',
                ),
                const SizedBox(height: 12),
                const _FeatureRow(
                  badge: '✎',
                  title: '나만의 필기로 더 깊은 이해',
                  subtitle: '하이라이트, 메모, 북마크',
                ),
                const SizedBox(height: 12),
                const _FeatureRow(
                  badge: 'Q',
                  title: '노트 속 퀴즈로 바로 확인',
                  subtitle: '틀린 문제는 자동으로 오답노트에',
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: '시작하기  →',
                  height: 50,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningIllustration extends StatelessWidget {
  const _LearningIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            top: 8,
            child: Transform.rotate(
              angle: 0.14,
              child: const _Note(color: AppColors.coralSoft),
            ),
          ),
          Positioned(
            right: 14,
            top: 20,
            child: Transform.rotate(
              angle: -0.14,
              child: const _Note(color: AppColors.background),
            ),
          ),
          const Positioned(left: 52, top: 60, child: _NoteLines()),
          const Positioned(right: 47, top: 82, child: _NoteLines()),
          Positioned(
            left: 113,
            top: 126,
            child: SvgPicture.asset(
              'assets/images/auth/reader_head.svg',
              width: 70,
              height: 70,
            ),
          ),
          Positioned(
            left: 129,
            top: 146,
            child: SvgPicture.asset('assets/images/auth/eye.svg', width: 6),
          ),
          Positioned(
            left: 159,
            top: 146,
            child: SvgPicture.asset('assets/images/auth/eye.svg', width: 6),
          ),
          const Positioned(left: 97, top: 167, child: _Book()),
          const Positioned(right: 18, top: 10, child: _Sparks()),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 138,
    height: 168,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _NoteLines extends StatelessWidget {
  const _NoteLines();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (index) => Container(
        width: 78,
        height: 6,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: index == 3 ? AppColors.yellow : AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}

class _Book extends StatelessWidget {
  const _Book();
  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    height: 58,
    decoration: BoxDecoration(
      color: AppColors.sageDark,
      borderRadius: BorderRadius.circular(18),
    ),
    alignment: Alignment.center,
    child: Container(width: 4, color: AppColors.background),
  );
}

class _Sparks extends StatelessWidget {
  const _Sparks();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        width: 8,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 9),
      Container(
        width: 8,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ],
  );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.badge,
    required this.title,
    required this.subtitle,
  });
  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.coralSoft,
        child: Text(badge, style: const TextStyle(color: AppColors.coralDark)),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontSize: 15),
            ),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

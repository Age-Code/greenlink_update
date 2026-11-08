import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/features/profile/presentation/content/policy_texts.dart';

/// 개인정보 처리방침 / 이용약관 / 내 데이터 안내, read in the 720 column.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.kindSlug});

  final String kindSlug;

  @override
  Widget build(BuildContext context) {
    final kind = PolicyKind.fromSlug(kindSlug);
    return AppResponsiveScaffold(
      maxWidth: AppLayout.readingMaxWidth,
      leading: IconButton(
        tooltip: '마이로 돌아가기',
        onPressed:
            () => context.canPop() ? context.pop() : context.go(AppRoutes.my),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(kind?.title ?? '안내'),
      body:
          kind == null
              ? const Center(child: Text('문서를 찾을 수 없어요.'))
              : AppPageBody(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      border: Border.all(color: AppColors.homePeach),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.coralDark,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            policyDraftNotice,
                            style: TextStyle(
                              color: AppColors.homeBrown,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    kind.title,
                    style: const TextStyle(
                      color: AppColors.homeInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '시행일 $policyEffectiveDate',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final section in policySections(kind)) ...[
                    Text(
                      section.heading,
                      style: const TextStyle(
                        color: AppColors.homeInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
    );
  }
}

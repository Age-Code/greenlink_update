// 물 부족 배너 위젯

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// WaterShortageBanner — 물 부족 배너 위젯
class WaterShortageBanner extends StatelessWidget {
  final String? plantName;
  final double soilMoisturePercent;

  const WaterShortageBanner({
    super.key,
    required this.soilMoisturePercent,
    this.plantName,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final trimmedName = plantName?.trim();
    final body = trimmedName == null || trimmedName.isEmpty
        ? '토양 수분이 부족해요. 물이 필요합니다.'
        : '$trimmedName 토양 수분이 부족해요. 물이 필요합니다.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: AppColors.warningText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '물부족 알림',
                  style: TextStyle(
                    color: AppColors.warningText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '현재 토양 수분: ${soilMoisturePercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.bodyMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

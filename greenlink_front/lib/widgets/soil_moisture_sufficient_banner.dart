// 과습 배너 위젯

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// SoilMoistureSufficientBanner — 과습 배너 위젯
class SoilMoistureSufficientBanner extends StatelessWidget {
  final double soilMoisturePercent;

  const SoilMoistureSufficientBanner({
    super.key,
    required this.soilMoisturePercent,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBorder),
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
              Icons.water_drop_outlined,
              color: AppColors.infoText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '수분 충분',
                  style: TextStyle(
                    color: AppColors.infoText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '현재 토양 수분이 ${soilMoisturePercent.toStringAsFixed(1)}%입니다.',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '지금은 물을 더 주지 않아도 괜찮아요.',
                  style: TextStyle(
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

// 공통 Chip 위젯

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ChipStatus — 공통 Chip 위젯
enum ChipStatus { neutral, positive, warning, danger, info }

// GreenlinkChip — 공통 Chip 위젯
class GreenlinkChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const GreenlinkChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: AppColors.canvas,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primaryStrong,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryStrong : AppColors.bodyMuted,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        fontSize: 14,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.hairline,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

// GreenlinkStatusChip — 공통 Chip 위젯
class GreenlinkStatusChip extends StatelessWidget {
  final String label;
  final ChipStatus status;

  const GreenlinkStatusChip({
    Key? key,
    required this.label,
    this.status = ChipStatus.neutral,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case ChipStatus.positive:
        bg = AppColors.primarySoft;
        fg = AppColors.primaryStrong;
        break;
      case ChipStatus.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warningText;
        break;
      case ChipStatus.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.dangerText;
        break;
      case ChipStatus.info:
        bg = AppColors.infoBg;
        fg = AppColors.infoText;
        break;
      case ChipStatus.neutral:
        bg = const Color(0xFFF2F2F0);
        fg = AppColors.bodyMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

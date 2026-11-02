// 선택 가능한 사용자 식물 카드 위젯

import 'package:flutter/material.dart';
import '../models/user_plant_models.dart';

// SelectableUserPlantSummaryCard — 카드 위젯
class SelectableUserPlantSummaryCard extends StatelessWidget {
  final UserPlantSummary plant;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableUserPlantSummaryCard({
    Key? key,
    required this.plant,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusText = "자라는 중";
    if (plant.status == 'HARVESTABLE') statusText = "수확 가능";
    if (plant.status == 'HARVESTED') statusText = "수확 완료";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondary.withValues(alpha: 0.3) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: plant.imageUrl != null
                  ? ClipOval(child: Image.network(plant.imageUrl!, fit: BoxFit.cover))
                  : Icon(Icons.local_florist, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                  Text(plant.plantName, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColorDark, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (plant.remainingDays != null)
                        Text("D-${plant.remainingDays}", style: theme.textTheme.bodySmall),
                    ],
                  )
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor)
            else
              Icon(Icons.radio_button_unchecked, color: theme.disabledColor)
          ],
        ),
      ),
    );
  }
}

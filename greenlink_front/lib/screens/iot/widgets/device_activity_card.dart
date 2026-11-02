// 장치 활동 카드 — 조명 상태와 최근 명령 실행 결과

import 'package:flutter/material.dart';

import '../../../core/utils/relative_time.dart';
import '../../../models/iot_models.dart';
import '../../../theme/app_theme.dart';

class DeviceActivityCard extends StatelessWidget {
  final LightState? light;
  final List<CommandSummary> commands;

  const DeviceActivityCard({
    super.key,
    required this.light,
    required this.commands,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primaryStrong,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '장치 활동',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _LightChip(light: light),
            ],
          ),
          const SizedBox(height: 14),
          if (commands.isEmpty)
            const Text(
              '아직 실행한 명령이 없어요.',
              style: TextStyle(fontSize: 13, color: AppColors.bodyMuted),
            )
          else
            ...commands.map((command) => _CommandRow(command: command)),
        ],
      ),
    );
  }
}

class _LightChip extends StatelessWidget {
  final LightState? light;

  const _LightChip({required this.light});

  @override
  Widget build(BuildContext context) {
    final known = light != null;
    final on = light?.on == true;
    final label = !known ? '조명 상태 모름' : (on ? '조명 켜짐' : '조명 꺼짐');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: on ? AppColors.warningBg : AppColors.surfacePearl,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? AppColors.warningBorder : AppColors.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
            size: 14,
            color: on ? AppColors.warningText : AppColors.bodyMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? AppColors.warningText : AppColors.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  final CommandSummary command;

  const _CommandRow({required this.command});

  static const _typeLabels = {
    'WATER': '물 주기',
    'LIGHT_ON': '조명 켜기',
    'LIGHT_OFF': '조명 끄기',
    'SENSOR_REFRESH': '센서 새로고침',
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, statusLabel) = switch (command.commandStatus) {
      'SUCCESS' => (Icons.check_circle_rounded, AppColors.successText, '완료'),
      'FAILED' => (Icons.error_rounded, AppColors.dangerText, '실패'),
      'CANCELLED' => (Icons.cancel_rounded, AppColors.bodySoft, '취소됨'),
      'PROCESSING' => (Icons.autorenew_rounded, AppColors.infoText, '실행 중'),
      _ => (Icons.schedule_rounded, AppColors.infoText, '대기 중'),
    };
    final when = formatRelativeTimeString(
      command.completedAt ?? command.requestedAt,
    );
    final showMessage =
        command.commandStatus == 'FAILED' &&
        (command.resultMessage ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_typeLabels[command.commandType] ?? command.commandType} · $statusLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.body,
                  ),
                ),
                if (showMessage)
                  Text(
                    command.resultMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.dangerText,
                    ),
                  ),
              ],
            ),
          ),
          if (when != null)
            Text(
              when,
              style: const TextStyle(fontSize: 12, color: AppColors.bodySoft),
            ),
        ],
      ),
    );
  }
}

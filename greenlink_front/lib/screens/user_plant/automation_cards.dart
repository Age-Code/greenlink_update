// 자동화 카드 위젯 — 학습 모델과 로그 표시

import 'package:flutter/material.dart';
import '../../models/automation_models.dart';
import '../../theme/app_theme.dart';

// AutomationModelCard — 카드 위젯
class AutomationModelCard extends StatelessWidget {
  final AutomationModelModel? model;
  final bool isTraining;
  final bool isLoadingModel;
  final VoidCallback onTrain;
  final VoidCallback onRefresh;

  const AutomationModelCard({
    Key? key,
    required this.model,
    required this.isTraining,
    required this.isLoadingModel,
    required this.onTrain,
    required this.onRefresh,
  }) : super(key: key);

  // 표시용 문자열 포맷
  String _fmtDouble(double? v, {int digits = 1}) =>
      v == null ? '-' : v.toStringAsFixed(digits);

  // 표시용 문자열 포맷
  String _fmtInt(int? v) => v == null ? '-' : v.toString();

  // 표시용 문자열 포맷
  String _fmtScore(double? v) =>
      v == null ? '-' : '${(v * 100).toStringAsFixed(0)}%';

  // 표시용 문자열 포맷
  String _fmtStatus(String? s) {
    switch (s) {
      case 'READY': return '사용 가능';
      case 'INSUFFICIENT_DATA': return '데이터 부족';
      case 'FAILED': return '학습 실패';
      default: return s ?? '-';
    }
  }

  // 상태 표시값 변환
  Color _statusColor(String? s) {
    switch (s) {
      case 'READY': return AppColors.successText;
      case 'INSUFFICIENT_DATA': return AppColors.warningText;
      case 'FAILED': return AppColors.dangerText;
      default: return AppColors.bodyMuted;
    }
  }

  // 상태 표시값 변환
  Color _statusBg(String? s) {
    switch (s) {
      case 'READY': return AppColors.successBg;
      case 'INSUFFICIENT_DATA': return AppColors.warningBg;
      case 'FAILED': return AppColors.dangerBg;
      default: return AppColors.canvasGreenTint;
    }
  }

  // 표시용 문자열 포맷
  String _fmtDateTime(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';
    } catch (_) { return iso; }
  }

  // 숫자 두 자리 문자열 변환
  String _p(int n) => n.toString().padLeft(2, '0');

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('학습 모델', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
              // Refresh button
              IconButton(
                onPressed: isLoadingModel ? null : onRefresh,
                icon: isLoadingModel
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryStrong))
                    : const Icon(Icons.refresh_rounded, color: AppColors.primaryStrong, size: 20),
                tooltip: '새로고침',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(10)),
            child: const Text(
              '학습 모델은 기존 센서 데이터와 제어 기록을 바탕으로 식물별 추천 기준값을 계산합니다. 데이터가 부족하면 기본 기준값을 사용합니다.',
              style: TextStyle(fontSize: 12, color: AppColors.bodyMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),

          if (model == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('아직 학습된 모델이 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
              ),
            )
          else ...[
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(model!.modelStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_fmtStatus(model!.modelStatus),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(model!.modelStatus))),
                ),
                const SizedBox(width: 10),
                Text('신뢰도 ${_fmtScore(model!.confidenceScore)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
              ],
            ),
            const SizedBox(height: 14),
            // Recommended thresholds
            _ModelRow(label: '추천 물 주기 기준', value: '${_fmtDouble(model!.recommendedWaterThresholdPercent)}%'),
            _ModelRow(label: '추천 LED ON 기준', value: '${_fmtDouble(model!.recommendedLightOnThresholdLux)} lux'),
            _ModelRow(label: '추천 LED OFF 기준', value: '${_fmtDouble(model!.recommendedLightOffThresholdLux)} lux'),
            const Divider(height: 20, color: AppColors.hairline),
            _ModelRow(label: '토양수분 데이터', value: '${_fmtInt(model!.soilDataCount)}개'),
            _ModelRow(label: '조도 데이터', value: '${_fmtInt(model!.lightDataCount)}개'),
            _ModelRow(label: '급수 명령 수', value: '${_fmtInt(model!.waterCommandCount)}회'),
            _ModelRow(label: '평균 토양수분 감소량', value: '${_fmtDouble(model!.avgDryRatePerHour)}/h'),
            _ModelRow(label: '물 주기 후 평균 회복량', value: '${_fmtDouble(model!.avgWaterRecoveryPercent)}%'),
            const Divider(height: 20, color: AppColors.hairline),
            _ModelRow(label: '마지막 학습 시각', value: _fmtDateTime(model!.lastTrainedAt)),
          ],

          const SizedBox(height: 16),
          // Train button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isTraining ? null : onTrain,
              icon: isTraining
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Icon(Icons.model_training_rounded, size: 18),
              label: Text(isTraining ? '학습 중...' : '학습 실행'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _ModelRow — 내부 위젯
class _ModelRow extends StatelessWidget {
  final String label;
  final String value;
  const _ModelRow({required this.label, required this.value});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

// AutomationLogCard — 카드 위젯
class AutomationLogCard extends StatelessWidget {
  final List<AutomationLogModel> logs;
  final bool isLoading;

  const AutomationLogCard({Key? key, required this.logs, required this.isLoading}) : super(key: key);

  // 로그 타입 표시값 변환
  String _typeLabel(String t) {
    switch (t) {
      case 'AUTO_WATER': return '자동 급수 실행';
      case 'AUTO_LIGHT_ON': return '자동 조명 켜기';
      case 'AUTO_LIGHT_OFF': return '자동 조명 끄기';
      case 'SKIP_WATER': return '자동 급수 건너뜀';
      case 'SKIP_LIGHT': return '자동 조명 건너뜀';
      default: return t;
    }
  }

  // 로그 타입 표시값 변환
  Color _typeColor(String t) {
    if (t.startsWith('AUTO_')) return AppColors.successText;
    if (t.startsWith('SKIP_')) return AppColors.warningText;
    return AppColors.bodyMuted;
  }

  // 로그 타입 표시값 변환
  Color _typeBg(String t) {
    if (t.startsWith('AUTO_')) return AppColors.successBg;
    if (t.startsWith('SKIP_')) return AppColors.warningBg;
    return AppColors.canvasGreenTint;
  }

  // 로그 타입 표시값 변환
  IconData _typeIcon(String t) {
    switch (t) {
      case 'AUTO_WATER': return Icons.water_drop_rounded;
      case 'AUTO_LIGHT_ON': return Icons.light_mode_rounded;
      case 'AUTO_LIGHT_OFF': return Icons.nightlight_rounded;
      case 'SKIP_WATER': return Icons.water_drop_outlined;
      case 'SKIP_LIGHT': return Icons.light_mode_outlined;
      default: return Icons.info_outline;
    }
  }

  // 표시용 문자열 포맷
  String _fmtDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';
    } catch (_) { return iso; }
  }

  // 숫자 두 자리 문자열 변환
  String _p(int n) => n.toString().padLeft(2, '0');

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 12),
              const Text('자동화 로그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '자동화 로그에서는 자동 급수·조명 실행 여부와 건너뛴 이유를 확인할 수 있습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.bodyMuted, height: 1.5),
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primaryStrong, strokeWidth: 2)))
          else if (logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('자동화 로그가 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final log = logs[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.canvasGreenTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _typeBg(log.automationType), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_typeIcon(log.automationType), size: 12, color: _typeColor(log.automationType)),
                                const SizedBox(width: 4),
                                Text(_typeLabel(log.automationType),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor(log.automationType))),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(_fmtDateTime(log.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.bodySoft)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(log.message, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
                      if (log.triggerValue != null && log.thresholdValue != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '센서값: ${log.triggerValue!.toStringAsFixed(1)} / 기준: ${log.thresholdValue!.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.bodyMuted),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

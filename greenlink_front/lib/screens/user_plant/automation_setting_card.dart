// 자동화 설정 카드 — 급수/조명 임계치와 안전 모드 입력

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/automation_models.dart';
import '../../theme/app_theme.dart';

// AutomationStatusCard — 카드 위젯
class AutomationStatusCard extends StatelessWidget {
  final AutomationSettingModel setting;
  final ValueChanged<bool> onWaterChanged;
  final ValueChanged<bool> onLightChanged;
  final ValueChanged<bool> onOptimizeChanged;
  final ValueChanged<bool>? onWateringSafetyChanged;
  final ValueChanged<String> onDecisionModeChanged;

  const AutomationStatusCard({
    Key? key,
    required this.setting,
    required this.onWaterChanged,
    required this.onLightChanged,
    required this.onOptimizeChanged,
    required this.onWateringSafetyChanged,
    required this.onDecisionModeChanged,
  }) : super(key: key);

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return _AutoCard(
      icon: Icons.auto_mode_rounded,
      title: '자동화 상태',
      child: Column(
        children: [
          _SwitchRow(
            label: '자동 물 주기',
            icon: Icons.water_drop_outlined,
            value: setting.autoWaterEnabled,
            onChanged: onWaterChanged,
          ),
          const _CardDivider(),
          _SwitchRow(
            label: '자동 조명',
            icon: Icons.light_mode_outlined,
            value: setting.autoLightEnabled,
            onChanged: onLightChanged,
          ),
          const _CardDivider(),
          _SwitchRow(
            label: '학습 기반 자동 최적화',
            icon: Icons.psychology_outlined,
            value: setting.autoOptimizeEnabled,
            onChanged: onOptimizeChanged,
          ),
          const _CardDivider(),
          _SafetySwitchRow(
            value: setting.wateringSafetyEnabled,
            onChanged: onWateringSafetyChanged,
          ),
          const _CardDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.bodyMuted,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '자동화 판단 방식',
                    style: TextStyle(fontSize: 15, color: AppColors.ink),
                  ),
                ),
                DropdownButton<String>(
                  // 목록에 없는 값이 오면 DropdownButton이 assert로 멈추므로 HYBRID로 표시한다.
                  value: const ['RULE_BASED', 'HYBRID', 'LEARNING_BASED']
                          .contains(setting.decisionMode)
                      ? setting.decisionMode
                      : 'HYBRID',
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'RULE_BASED',
                      child: Text('기본 기준값만 사용'),
                    ),
                    DropdownMenuItem(
                      value: 'HYBRID',
                      child: Text('학습값 우선, 없으면 기본값'),
                    ),
                    DropdownMenuItem(
                      value: 'LEARNING_BASED',
                      child: Text('학습 모델 우선 사용'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) onDecisionModeChanged(v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// AutomationThresholdCard — 카드 위젯
class AutomationThresholdCard extends StatefulWidget {
  final AutomationSettingModel setting;
  final bool isSaving;
  final Future<void> Function(
    AutomationSettingModel updated,
    String startTime,
    String endTime,
  )
  onSave;

  const AutomationThresholdCard({
    Key? key,
    required this.setting,
    required this.isSaving,
    required this.onSave,
  }) : super(key: key);

  // State 객체 생성
  @override
  State<AutomationThresholdCard> createState() =>
      _AutomationThresholdCardState();
}

// _AutomationThresholdCardState — 화면 상태와 이벤트 처리
class _AutomationThresholdCardState extends State<AutomationThresholdCard> {
  late TextEditingController _waterThreshold;
  late TextEditingController _waterCooldown;
  late TextEditingController _lightOn;
  late TextEditingController _lightOff;
  late TextEditingController _lightCooldown;
  late TextEditingController _minData;
  String _lightStartTime = '00:00';
  String _lightEndTime = '23:59';

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _initControllers(widget.setting);
  }

  // 초기값 설정 — 컨트롤러는 한 번만 생성
  void _initControllers(AutomationSettingModel s) {
    _waterThreshold = TextEditingController();
    _waterCooldown = TextEditingController();
    _lightOn = TextEditingController();
    _lightOff = TextEditingController();
    _lightCooldown = TextEditingController();
    _minData = TextEditingController();
    _syncFromSetting(s);
  }

  // 설정값을 입력 필드에 반영 — 기존 컨트롤러 재사용
  void _syncFromSetting(AutomationSettingModel s) {
    _waterThreshold.text = s.waterThresholdPercent.toStringAsFixed(1);
    _waterCooldown.text = s.waterCooldownMinutes.toString();
    _lightOn.text = s.lightOnThresholdLux.toStringAsFixed(1);
    _lightOff.text = s.lightOffThresholdLux.toStringAsFixed(1);
    _lightCooldown.text = s.lightCooldownMinutes.toString();
    _minData.text = s.minLearningDataCount.toString();
    _lightStartTime = _toHHmm(s.lightStartTime);
    _lightEndTime = _toHHmm(s.lightEndTime);
  }

  // 기준값 관련 필드 변경 여부 — 스위치 토글 등 무관한 변경으로 입력 중인 값을 덮어쓰지 않기 위함
  bool _thresholdsChanged(AutomationSettingModel a, AutomationSettingModel b) {
    return a.automationSettingId != b.automationSettingId ||
        a.waterThresholdPercent != b.waterThresholdPercent ||
        a.waterCooldownMinutes != b.waterCooldownMinutes ||
        a.lightOnThresholdLux != b.lightOnThresholdLux ||
        a.lightOffThresholdLux != b.lightOffThresholdLux ||
        a.lightCooldownMinutes != b.lightCooldownMinutes ||
        a.minLearningDataCount != b.minLearningDataCount ||
        a.lightStartTime != b.lightStartTime ||
        a.lightEndTime != b.lightEndTime;
  }

  // 부모 설정 변경 반영 — 저장/학습 후 서버 보정값도 화면에 반영
  @override
  void didUpdateWidget(AutomationThresholdCard old) {
    super.didUpdateWidget(old);
    if (_thresholdsChanged(old.setting, widget.setting)) {
      _syncFromSetting(widget.setting);
    }
  }

  // 리소스 정리
  @override
  void dispose() {
    _waterThreshold.dispose();
    _waterCooldown.dispose();
    _lightOn.dispose();
    _lightOff.dispose();
    _lightCooldown.dispose();
    _minData.dispose();
    super.dispose();
  }

  // 시간 문자열 변환 — HH:mm 형식으로 축약
  String _toHHmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  // 선택 UI 표시 — 선택값을 상태에 반영
  Future<void> _pickTime(BuildContext ctx, bool isStart) async {
    final parts = (isStart ? _lightStartTime : _lightEndTime).split(':');
    final init = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: ctx, initialTime: init);
    // 시간 선택기가 떠 있는 동안 상위 화면이 다시 그려져 이 카드가 사라졌을 수 있다.
    if (!mounted) return;
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _lightStartTime = formatted;
        } else {
          _lightEndTime = formatted;
        }
      });
    }
  }

  // 이벤트 처리 — 입력값 검증 후 콜백 호출
  void _handleSave() {
    final updated = AutomationSettingModel(
      automationSettingId: widget.setting.automationSettingId,
      userPlantId: widget.setting.userPlantId,
      autoWaterEnabled: widget.setting.autoWaterEnabled,
      autoLightEnabled: widget.setting.autoLightEnabled,
      autoOptimizeEnabled: widget.setting.autoOptimizeEnabled,
      wateringSafetyEnabled: widget.setting.wateringSafetyEnabled,
      decisionMode: widget.setting.decisionMode,
      minLearningDataCount: int.tryParse(_minData.text.trim()) ?? 30,
      waterThresholdPercent:
          double.tryParse(_waterThreshold.text.trim()) ?? 35.0,
      waterCooldownMinutes: int.tryParse(_waterCooldown.text.trim()) ?? 30,
      lightOnThresholdLux: double.tryParse(_lightOn.text.trim()) ?? 300.0,
      lightOffThresholdLux: double.tryParse(_lightOff.text.trim()) ?? 500.0,
      lightStartTime: widget.setting.lightStartTime,
      lightEndTime: widget.setting.lightEndTime,
      lightCooldownMinutes: int.tryParse(_lightCooldown.text.trim()) ?? 10,
    );
    widget.onSave(updated, _lightStartTime, _lightEndTime);
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return _AutoCard(
      icon: Icons.settings_outlined,
      title: '기준값 설정',
      child: Column(
        children: [
          _NumInput(
            label: '물 주기 기준 토양수분',
            unit: '%',
            controller: _waterThreshold,
            isDecimal: true,
          ),
          _NumInput(label: '물 주기 쿨다운', unit: '분', controller: _waterCooldown),
          _NumInput(
            label: 'LED ON 기준 조도',
            unit: 'lux',
            controller: _lightOn,
            isDecimal: true,
          ),
          _NumInput(
            label: 'LED OFF 기준 조도',
            unit: 'lux',
            controller: _lightOff,
            isDecimal: true,
          ),
          const SizedBox(height: 4),
          _TimePickerRow(
            label: '조명 시작 시간',
            value: _lightStartTime,
            onTap: () => _pickTime(context, true),
          ),
          _TimePickerRow(
            label: '조명 종료 시간',
            value: _lightEndTime,
            onTap: () => _pickTime(context, false),
          ),
          const SizedBox(height: 4),
          _NumInput(label: '조명 쿨다운', unit: '분', controller: _lightCooldown),
          _NumInput(label: '최소 학습 데이터 개수', unit: '개', controller: _minData),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.isSaving ? null : _handleSave,
              icon: widget.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(widget.isSaving ? '저장 중...' : '설정 저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStrong,
                foregroundColor: AppColors.canvas,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// _AutoCard — 카드 위젯
class _AutoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AutoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// _SwitchRow — 내부 위젯
class _SwitchRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: value ? AppColors.primaryStrong : AppColors.bodyMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryStrong,
            activeTrackColor: AppColors.primarySoft,
          ),
        ],
      ),
    );
  }
}

// _SafetySwitchRow — 내부 위젯
class _SafetySwitchRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SafetySwitchRow({required this.value, required this.onChanged});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안전 설정',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryStrong,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 18,
                color: value ? AppColors.primaryStrong : AppColors.bodyMuted,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '급수 보호모드',
                  style: TextStyle(fontSize: 15, color: AppColors.ink),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primaryStrong,
                activeTrackColor: AppColors.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '켜져 있으면 토양 수분이 높거나 짧은 시간에 물주기를 여러 번 요청할 때 자동으로 차단합니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.bodyMuted,
              height: 1.45,
            ),
          ),
          if (!value) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE1A8)),
              ),
              child: const Text(
                '보호모드가 꺼져 있어요. 시연 또는 테스트 상황에서만 사용하세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A5B00),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// _CardDivider — 내부 위젯
class _CardDivider extends StatelessWidget {
  const _CardDivider();
  // 위젯 렌더링
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.hairline);
}

// _NumInput — 내부 위젯
class _NumInput extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool isDecimal;

  const _NumInput({
    required this.label,
    required this.unit,
    required this.controller,
    this.isDecimal = false,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.bodyMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: isDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: isDecimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                  : [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.bodyMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryFocus,
                    width: 1.5,
                  ),
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _TimePickerRow — 내부 위젯
class _TimePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.bodyMuted),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.primaryStrong,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

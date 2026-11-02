// 자동화 섹션 — 설정/학습/모델/로그 조회

import 'package:flutter/material.dart';
import '../../models/automation_models.dart';
import '../../services/automation_service.dart';
import '../../theme/app_theme.dart';
import 'automation_setting_card.dart';
import 'automation_cards.dart';

// AutomationSection — 자동화 섹션 — 설정/학습/모델/로그 조회
class AutomationSection extends StatefulWidget {
  final int userPlantId;

  const AutomationSection({Key? key, required this.userPlantId})
    : super(key: key);

  // State 객체 생성
  @override
  State<AutomationSection> createState() => _AutomationSectionState();
}

// _AutomationSectionState — 화면 상태와 이벤트 처리
class _AutomationSectionState extends State<AutomationSection> {
  final AutomationService _service = AutomationService();

  bool _isLoadingSetting = false;
  bool _isSavingSetting = false;
  bool _isTraining = false;
  bool _isLoadingModel = false;
  bool _isLoadingLogs = false;

  AutomationSettingModel? _setting;
  AutomationModelModel? _model;
  List<AutomationLogModel> _logs = [];
  String? _errorMessage;

  // 로컬 토글 상태 (설정 저장 전 임시)
  bool _autoWaterEnabled = true;
  bool _autoLightEnabled = true;
  bool _autoOptimizeEnabled = true;
  bool _wateringSafetyEnabled = true;
  String _decisionMode = 'HYBRID';

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadAll() async {
    await Future.wait([_loadSetting(), _loadModel(), _loadLogs()]);
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadSetting() async {
    setState(() {
      _isLoadingSetting = true;
      _errorMessage = null;
    });
    final res = await _service.getAutomationSetting(widget.userPlantId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _setting = res.data;
        _autoWaterEnabled = res.data!.autoWaterEnabled;
        _autoLightEnabled = res.data!.autoLightEnabled;
        _autoOptimizeEnabled = res.data!.autoOptimizeEnabled;
        _wateringSafetyEnabled = res.data!.wateringSafetyEnabled;
        _decisionMode = res.data!.decisionMode;
        _isLoadingSetting = false;
      });
    } else {
      setState(() {
        _errorMessage = '자동화 설정을 불러오지 못했습니다.';
        _isLoadingSetting = false;
      });
    }
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadModel() async {
    setState(() => _isLoadingModel = true);
    final model = await _service.getLatestAutomationModel(widget.userPlantId);
    if (!mounted) return;
    setState(() {
      _model = model;
      _isLoadingModel = false;
    });
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadLogs() async {
    setState(() => _isLoadingLogs = true);
    final res = await _service.getAutomationLogs(widget.userPlantId);
    if (!mounted) return;
    setState(() {
      _logs = res.data ?? [];
      _isLoadingLogs = false;
    });
  }

  // 자동화 설정 저장 — 성공 시 설정과 로그 재조회
  Future<void> _saveSetting(
    AutomationSettingModel updated,
    String startTime,
    String endTime,
  ) async {
    setState(() => _isSavingSetting = true);
    final res = await _service.updateAutomationSetting(
      widget.userPlantId,
      updated,
      lightStartTimeRaw: startTime,
      lightEndTimeRaw: endTime,
    );
    if (!mounted) return;
    setState(() => _isSavingSetting = false);

    if (res.success) {
      _showSnack('자동화 설정이 저장되었습니다. ✅');
      await _loadSetting();
      await _loadLogs();
    } else {
      _showSnack('자동화 설정 저장에 실패했습니다. ❌');
    }
  }

  // 과습 안전 모드 변경 — 저장 실패 시 이전 값 복원
  Future<void> _updateWateringSafety(bool enabled) async {
    final previous = _wateringSafetyEnabled;

    setState(() {
      _wateringSafetyEnabled = enabled;
      _isSavingSetting = true;
    });

    final res = await _service.updateAutomationSetting(
      widget.userPlantId,
      _currentSetting(),
    );

    if (!mounted) return;

    setState(() => _isSavingSetting = false);

    if (res.success && res.data != null) {
      setState(() {
        _setting = res.data;
        _autoWaterEnabled = res.data!.autoWaterEnabled;
        _autoLightEnabled = res.data!.autoLightEnabled;
        _autoOptimizeEnabled = res.data!.autoOptimizeEnabled;
        _wateringSafetyEnabled = res.data!.wateringSafetyEnabled;
        _decisionMode = res.data!.decisionMode;
      });
      _showSnack(enabled ? '급수 보호모드가 켜졌습니다.' : '급수 보호모드가 꺼졌습니다.');
      await _loadLogs();
    } else {
      setState(() => _wateringSafetyEnabled = previous);
      _showSnack(res.message.isNotEmpty ? res.message : '급수 보호모드 저장에 실패했습니다.');
    }
  }

  // 자동화 학습 실행 — 성공 시 설정/모델/로그 재조회
  Future<void> _trainModel() async {
    setState(() => _isTraining = true);
    final res = await _service.trainAutomationModel(widget.userPlantId);
    if (!mounted) return;
    setState(() => _isTraining = false);

    if (res.success) {
      _showSnack('학습이 완료되었습니다. 🤖');
      await Future.wait([_loadSetting(), _loadModel(), _loadLogs()]);
    } else {
      _showSnack('학습 실행에 실패했습니다. ❌');
    }
  }

  // 스낵바 표시 — 성공/오류 색상 분기
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // 현재 자동화 설정 모델 생성 — 미조회 상태는 화면 값으로 보정
  AutomationSettingModel _currentSetting() {
    final base =
        _setting ??
        AutomationSettingModel(
          userPlantId: widget.userPlantId,
          autoWaterEnabled: _autoWaterEnabled,
          autoLightEnabled: _autoLightEnabled,
          autoOptimizeEnabled: _autoOptimizeEnabled,
          wateringSafetyEnabled: _wateringSafetyEnabled,
          decisionMode: _decisionMode,
        );
    return AutomationSettingModel(
      automationSettingId: base.automationSettingId,
      userPlantId: base.userPlantId,
      autoWaterEnabled: _autoWaterEnabled,
      autoLightEnabled: _autoLightEnabled,
      autoOptimizeEnabled: _autoOptimizeEnabled,
      wateringSafetyEnabled: _wateringSafetyEnabled,
      decisionMode: _decisionMode,
      minLearningDataCount: base.minLearningDataCount,
      waterThresholdPercent: base.waterThresholdPercent,
      waterCooldownMinutes: base.waterCooldownMinutes,
      lightOnThresholdLux: base.lightOnThresholdLux,
      lightOffThresholdLux: base.lightOffThresholdLux,
      lightStartTime: base.lightStartTime,
      lightEndTime: base.lightEndTime,
      lightCooldownMinutes: base.lightCooldownMinutes,
    );
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '자동화 관리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.canvasGreenTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          child: const Text(
            '자동화 관리는 토양수분과 조도 데이터를 기반으로 물 주기와 조명을 자동으로 제어합니다. '
            '학습 기반 자동 최적화를 켜면 누적된 센서 데이터와 제어 기록을 분석해 식물별 기준값을 추천하거나 자동 반영할 수 있습니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.bodyMuted,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoadingSetting)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                color: AppColors.primaryStrong,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.dangerText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          AutomationStatusCard(
            setting: _currentSetting(),
            onWaterChanged: (v) => setState(() => _autoWaterEnabled = v),
            onLightChanged: (v) => setState(() => _autoLightEnabled = v),
            onOptimizeChanged: (v) => setState(() => _autoOptimizeEnabled = v),
            onWateringSafetyChanged: _isSavingSetting
                ? null
                : _updateWateringSafety,
            onDecisionModeChanged: (v) => setState(() => _decisionMode = v),
          ),
          const SizedBox(height: 16),

          AutomationThresholdCard(
            setting: _currentSetting(),
            isSaving: _isSavingSetting,
            onSave: _saveSetting,
          ),
          const SizedBox(height: 16),

          AutomationModelCard(
            model: _model,
            isTraining: _isTraining,
            isLoadingModel: _isLoadingModel,
            onTrain: _trainModel,
            onRefresh: _loadModel,
          ),
          const SizedBox(height: 16),

          AutomationLogCard(logs: _logs, isLoading: _isLoadingLogs),
        ],
      ],
    );
  }
}

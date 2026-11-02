// IoT 상태 화면 — 센서 조회, 물주기/조명/센서 새로고침 버튼

import 'package:flutter/material.dart';
import '../../models/iot_models.dart';
import '../../services/iot_service.dart';
import '../../core/config/camera_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mjpeg_stream_view.dart';
import '../../widgets/soil_moisture_sufficient_banner.dart';
import '../../widgets/water_shortage_banner.dart';

// IoT 상태 화면 — 센서/카메라/제어 명령 표시
class IotStatusPage extends StatefulWidget {
  final int userPlantId;
  final String plantName;

  const IotStatusPage({
    Key? key,
    required this.userPlantId,
    required this.plantName,
  }) : super(key: key);

  // State 객체 생성
  @override
  State<IotStatusPage> createState() => _IotStatusPageState();
}

// _IotStatusPageState — 화면 상태와 이벤트 처리
class _IotStatusPageState extends State<IotStatusPage> {
  final IotService _iotService = IotService();

  IotLatestStatus? _status;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isWatering = false;
  bool _isLightingOn = false;
  bool _isLightingOff = false;
  bool _isSensorRefreshing = false;

  int _cameraReloadKey = 0;
  bool _hasShownWaterShortageNotice = false;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  // 최신 IoT 상태 조회 — 성공 시 화면 상태 반영
  Future<void> _loadLatest({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    final res = await _iotService.getLatestStatus(widget.userPlantId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final latest = res.data!;
      setState(() {
        _status = latest;
        if (showLoading) _isLoading = false;
        _errorMessage = null;
      });
      _showWaterShortageSnackIfNeeded(latest);
    } else {
      setState(() {
        if (showLoading) _isLoading = false;
        _errorMessage = res.message;
      });
    }
  }

  // 센서 새로고침 요청 — 성공 시 2.5초 후 latest 재조회, 409면 스낵바
  Future<void> _onSensorRefresh() async {
    if (_isSensorRefreshing) return;

    setState(() => _isSensorRefreshing = true);

    try {
      final res = await _iotService.requestSensorRefresh(widget.userPlantId);
      if (!mounted) return;

      if (res.success) {
        _showSnack(
          res.message.isNotEmpty ? res.message : '센서 새로고침을 요청했습니다.',
          success: true,
        );

        await Future.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;

        _hasShownWaterShortageNotice = false;
        await _loadLatest(showLoading: false);
        return;
      }

      final message = res.message == '이미 센서 새로고침이 진행 중입니다.'
          ? '이미 센서 새로고침이 진행 중입니다.'
          : '센서 새로고침 요청에 실패했습니다.';
      _showSnack(message, success: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('센서 새로고침 요청에 실패했습니다.', success: false);
    } finally {
      if (mounted) {
        setState(() => _isSensorRefreshing = false);
      }
    }
  }

  // 수동 물주기 요청 — 서버 판정이 차단이면 사유를 안내하고 아니면 명령 전송
  Future<void> _onWater() async {
    if (_status?.canWater == false) {
      final moisture = _status!.soilMoisturePercent;
      _showSnack(
        _status!.waterBlockReason ??
            (moisture == null
                ? '토양 수분이 충분히 높아 지금은 물을 줄 수 없습니다.'
                : '토양 수분이 ${moisture.toStringAsFixed(1)}%로 충분히 높아 지금은 물을 줄 수 없습니다.'),
        success: false,
      );
      return;
    }

    setState(() => _isWatering = true);
    final res = await _iotService.requestWater(widget.userPlantId);
    if (!mounted) return;
    setState(() => _isWatering = false);
    _showSnack(
      res.success
          ? (res.message.isNotEmpty ? res.message : '물 주기 요청이 전송되었습니다.')
          : res.message,
      success: res.success,
    );
    // 카메라 스트림 유지를 위해 로딩 화면 없이 재조회
    await _loadLatest(showLoading: false);
  }

  // 조명 켜기 요청 — 성공 시 최신 상태 재조회
  Future<void> _onLightOn() async {
    setState(() => _isLightingOn = true);
    final res = await _iotService.lightOn(widget.userPlantId);
    if (!mounted) return;
    setState(() => _isLightingOn = false);
    _showSnack(
      res.success
          ? (res.message.isNotEmpty ? res.message : '조명을 켰습니다.')
          : res.message,
      success: res.success,
    );
    if (res.success) await _loadLatest(showLoading: false);
  }

  // 조명 끄기 요청 — 성공 시 최신 상태 재조회
  Future<void> _onLightOff() async {
    setState(() => _isLightingOff = true);
    final res = await _iotService.lightOff(widget.userPlantId);
    if (!mounted) return;
    setState(() => _isLightingOff = false);
    _showSnack(
      res.success
          ? (res.message.isNotEmpty ? res.message : '조명을 껐습니다.')
          : res.message,
      success: res.success,
    );
    if (res.success) await _loadLatest(showLoading: false);
  }

  // 스낵바 표시 — 성공/오류 색상 분기
  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.surfaceDark : AppColors.dangerText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 물 부족 알림 표시 — 같은 조회 주기에서 중복 방지
  void _showWaterShortageSnackIfNeeded(IotLatestStatus latest) {
    final moisture = latest.soilMoisturePercent;
    if (_hasShownWaterShortageNotice ||
        moisture == null ||
        !latest.isWaterShortage) {
      return;
    }

    _hasShownWaterShortageNotice = true;
    final plantName = widget.plantName.trim();
    final prefix = plantName.isEmpty ? '' : '$plantName ';
    _showSnack(
      '$prefix토양 수분이 부족해요. 물이 필요합니다. 현재 토양 수분: ${moisture.toStringAsFixed(1)}%',
      success: true,
    );
  }

  // 일시 문자열 포맷 — 파싱 실패 시 원문 반환
  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${p(dt.month)}-${p(dt.day)} ${p(dt.hour)}:${p(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }

  bool get _anyBusy =>
      _isWatering || _isLightingOn || _isLightingOff || _isSensorRefreshing;

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('${widget.plantName} IoT'),
        actions: [
          IconButton(
            icon: _isSensorRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 22),
            tooltip: '센서 새로고침',
            onPressed: (_isLoading || _isSensorRefreshing)
                ? null
                : _onSensorRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryStrong,
                ),
              ),
            )
          : _errorMessage != null
          ? _buildError()
          : _buildContent(),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.canvasGreenTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.bodyMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.bodyMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _isSensorRefreshing ? null : _onSensorRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isSensorRefreshing ? '새로고침 중...' : '센서 새로고침'),
            ),
          ],
        ),
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildContent() {
    final status = _status!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status.isWaterShortage && status.soilMoisturePercent != null) ...[
            WaterShortageBanner(
              plantName: widget.plantName,
              soilMoisturePercent: status.soilMoisturePercent!,
            ),
            const SizedBox(height: 16),
          ],
          if (status.isTooWet && status.soilMoisturePercent != null) ...[
            SoilMoistureSufficientBanner(
              soilMoisturePercent: status.soilMoisturePercent!,
            ),
            const SizedBox(height: 16),
          ],

          // 재배 공간
          if (status.growSpace != null) ...[
            _GrowSpaceCard(name: status.growSpace!.name),
            const SizedBox(height: 16),
          ],

          // 실시간 카메라
          _buildLiveCameraCard(),
          const SizedBox(height: 16),

          // 환경 데이터 2×2 grid
          _buildEnvironmentGrid(status.environment),
          const SizedBox(height: 16),
          _buildSensorRefreshPanel(),
          const SizedBox(height: 16),

          // 토양수분
          _buildSoilCard(status.soil, isWaterShortage: status.isWaterShortage),
          const SizedBox(height: 28),

          // 제어 섹션
          _buildControlSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildLiveCameraCard() {
    return _IotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 18,
                    color: AppColors.primaryStrong,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '실시간 카메라',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _cameraReloadKey++),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvasGreenTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppColors.primaryStrong,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '새로고침',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryStrong,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '현재 재배 공간의 실시간 화면입니다.',
            style: TextStyle(fontSize: 13, color: AppColors.bodyMuted),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: AppColors.canvasSoft,
              child: MjpegStreamView(
                key: ValueKey(_cameraReloadKey),
                streamUrl: CameraConfig.getCameraStreamUrl(widget.userPlantId),
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFFE74C3C)),
              SizedBox(width: 6),
              Text(
                'Real-time Camera',
                style: TextStyle(fontSize: 12, color: AppColors.bodyMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildEnvironmentGrid(EnvironmentData? env) {
    if (env == null) {
      return _IotCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(icon: Icons.thermostat_outlined, label: '환경 데이터'),
            const SizedBox(height: 16),
            const Text(
              '아직 측정 데이터가 없습니다.',
              style: TextStyle(color: AppColors.bodyMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '센서 새로고침은 온도·습도·조도 데이터를 다시 측정합니다.',
              style: TextStyle(color: AppColors.bodySoft, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                label: '온도',
                value: env.temperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFE8845A),
                statusLabel: _tempStatus(env.temperature),
                statusPositive: env.temperature >= 18 && env.temperature <= 28,
                measuredAt: env.measuredAt,
                formatTime: _formatDateTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                label: '습도',
                value: env.humidity.toStringAsFixed(1),
                unit: '%',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF5A9CE8),
                statusLabel: _humidityStatus(env.humidity),
                statusPositive: env.humidity >= 40 && env.humidity <= 70,
                measuredAt: env.measuredAt,
                formatTime: _formatDateTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                label: '조도',
                value: env.light.toStringAsFixed(0),
                unit: 'lux',
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFD4A017),
                statusLabel: _lightStatus(env.light),
                statusPositive: env.light >= 100,
                measuredAt: env.measuredAt,
                formatTime: _formatDateTime,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '센서 새로고침은 온도·습도·조도 데이터를 다시 측정합니다.',
          style: TextStyle(fontSize: 12, color: AppColors.bodySoft),
        ),
      ],
    );
  }

  // 온도 상태 라벨 반환
  String _tempStatus(double t) {
    if (t < 15) return '낮음';
    if (t > 30) return '높음';
    return '적정';
  }

  // 습도 상태 라벨 반환
  String _humidityStatus(double h) {
    if (h < 30) return '건조';
    if (h > 80) return '높음';
    return '안정';
  }

  // 조도 상태 라벨 반환
  String _lightStatus(double l) {
    if (l < 50) return '어두움';
    if (l < 200) return '보통';
    return '밝음';
  }

  // 화면 섹션 렌더링
  Widget _buildSoilCard(SoilData? soil, {required bool isWaterShortage}) {
    if (soil == null) {
      return _IotCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _CardTitle(icon: Icons.grass_outlined, label: '토양 수분'),
            SizedBox(height: 16),
            Text(
              '아직 측정 데이터가 없습니다.',
              style: TextStyle(color: AppColors.bodyMuted, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '토양수분은 ESP32 센서 주기에 따라 갱신됩니다.',
              style: TextStyle(color: AppColors.bodySoft, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final pct = soil.soilMoisturePercent;
    if (pct == null) {
      return _IotCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _CardTitle(icon: Icons.grass_outlined, label: '토양 수분'),
            SizedBox(height: 16),
            Text(
              '토양 수분 데이터 없음',
              style: TextStyle(color: AppColors.bodyMuted, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '토양수분은 ESP32 센서 주기에 따라 갱신됩니다.',
              style: TextStyle(color: AppColors.bodySoft, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 배너와 동일하게 서버 기준(shortageThresholdPercent) 우선 판정 사용
    final isLow = isWaterShortage;
    final isMid = pct < 60;

    Color trackColor;
    String statusLabel;
    bool isPositive;
    if (isLow) {
      trackColor = AppColors.dangerText;
      statusLabel = '건조 — 물이 필요해요';
      isPositive = false;
    } else if (isMid) {
      trackColor = AppColors.warningText;
      statusLabel = '적당한 수분';
      isPositive = true;
    } else {
      trackColor = AppColors.primaryStrong;
      statusLabel = '촉촉한 상태';
      isPositive = true;
    }

    return _IotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.grass_outlined, label: '토양 수분'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pct.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bodyMuted,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.primarySoft
                      : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPositive
                        ? AppColors.primaryStrong
                        : AppColors.dangerText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
          ),
          if (soil.measuredAt != null) ...[
            const SizedBox(height: 10),
            Text(
              '측정: ${_formatDateTime(soil.measuredAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.bodySoft),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            '토양수분은 ESP32 센서 주기에 따라 갱신됩니다.',
            style: TextStyle(fontSize: 12, color: AppColors.bodySoft),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildSensorRefreshPanel() {
    return _IotCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSensorRefreshing
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryStrong,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: AppColors.primaryStrong,
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '센서 새로고침',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '온도·습도·조도 데이터를 다시 측정합니다. 토양수분은 ESP32 센서 주기에 따라 갱신됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.bodyMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: (_isLoading || _anyBusy) ? null : _onSensorRefresh,
            child: Text(_isSensorRefreshing ? '새로고침 중...' : '실행'),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildControlSection() {
    final isTooWet = _status?.isTooWet == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '제어',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        _ControlButton(
          label: isTooWet ? '수분 충분' : '물 주기',
          description: isTooWet ? '지금은 물을 더 주지 않아도 괜찮아요' : '펌프를 작동해 물을 줍니다',
          icon: Icons.water_drop_rounded,
          iconBg: isTooWet ? AppColors.infoBg : const Color(0xFFDEEFFB),
          iconColor: isTooWet ? AppColors.infoText : const Color(0xFF3A8FC8),
          isLoading: _isWatering,
          isDisabled: _anyBusy || isTooWet,
          onPressed: _onWater,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                label: '조명 켜기',
                description: 'LED 켜기',
                icon: Icons.light_mode_rounded,
                iconBg: const Color(0xFFFFF8DC),
                iconColor: const Color(0xFFB8860B),
                isLoading: _isLightingOn,
                isDisabled: _anyBusy,
                onPressed: _onLightOn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                label: '조명 끄기',
                description: 'LED 끄기',
                icon: Icons.nightlight_round,
                iconBg: const Color(0xFFEEEEF5),
                iconColor: const Color(0xFF5A5A8F),
                isLoading: _isLightingOff,
                isDisabled: _anyBusy,
                onPressed: _onLightOff,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: (_isLoading || _anyBusy) ? null : _onSensorRefresh,
            icon: _isSensorRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_isSensorRefreshing ? '새로고침 중...' : '센서 새로고침'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '온도·습도·조도 데이터를 다시 측정합니다. 토양수분은 ESP32 센서 주기에 따라 갱신됩니다.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.bodySoft,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}


// _GrowSpaceCard — 카드 위젯
class _GrowSpaceCard extends StatelessWidget {
  final String name;
  const _GrowSpaceCard({required this.name});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.canvasGreenTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: AppColors.primaryStrong,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// _IotCard — 카드 위젯
class _IotCard extends StatelessWidget {
  final Widget child;
  const _IotCard({required this.child});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }
}

// _CardTitle — 내부 위젯
class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardTitle({required this.icon, required this.label});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryStrong),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// _SensorCard — 카드 위젯
class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final String statusLabel;
  final bool statusPositive;
  final String? measuredAt;
  final String Function(String?) formatTime;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.statusLabel,
    required this.statusPositive,
    this.measuredAt,
    required this.formatTime,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.bodyMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.bodyMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusPositive
                  ? AppColors.primarySoft
                  : AppColors.warningBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: statusPositive
                    ? AppColors.primaryStrong
                    : AppColors.warningText,
              ),
            ),
          ),
          if (measuredAt != null) ...[
            const SizedBox(height: 6),
            Text(
              formatTime(measuredAt),
              style: const TextStyle(fontSize: 11, color: AppColors.bodySoft),
            ),
          ],
        ],
      ),
    );
  }
}

// _ControlButton — 내부 위젯
class _ControlButton extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled;

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.bodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.bodyMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

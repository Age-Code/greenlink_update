// IoT API 모델

import '../core/constants/iot_thresholds.dart';

// IoT 상태 모델
// GET /api/user-plants/{userPlantId}/iot/latest 응답

// IotLatestStatus — IoT API 모델
class IotLatestStatus {
  final int userPlantId;
  final GrowSpaceInfo? growSpace;
  final EnvironmentData? environment;
  final SoilData? soil;
  final PlantImageData? latestImage;
  final WateringGuard? watering;
  final LightState? light; // 마지막으로 성공한 조명 명령 기준 (기록 없으면 null)
  final List<CommandSummary> recentCommands;

  IotLatestStatus({
    required this.userPlantId,
    this.growSpace,
    this.environment,
    this.soil,
    this.latestImage,
    this.watering,
    this.light,
    this.recentCommands = const [],
  });

  // JSON 응답을 모델로 변환
  factory IotLatestStatus.fromJson(Map<String, dynamic> json) =>
      IotLatestStatus(
        userPlantId: json['userPlantId'] ?? 0,
        growSpace: json['growSpace'] != null
            ? GrowSpaceInfo.fromJson(json['growSpace'])
            : null,
        environment: json['environment'] != null
            ? EnvironmentData.fromJson(json['environment'])
            : null,
        soil: json['soil'] != null ? SoilData.fromJson(json['soil']) : null,
        latestImage: json['latestImage'] != null
            ? PlantImageData.fromJson(json['latestImage'])
            : null,
        watering: json['watering'] != null
            ? WateringGuard.fromJson(json['watering'])
            : null,
        light: json['light'] != null ? LightState.fromJson(json['light']) : null,
        recentCommands: json['recentCommands'] is List
            ? (json['recentCommands'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(CommandSummary.fromJson)
                  .toList()
            : const [],
      );

  // 가장 최근 센서 측정 시각 — 환경/토양 중 늦은 쪽
  DateTime? get lastMeasuredAt {
    final times = [environment?.measuredAt, soil?.measuredAt]
        .whereType<String>()
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .toList();
    if (times.isEmpty) return null;
    times.sort();
    return times.last;
  }

  // 물 부족 여부 — 서버가 내려준 기준을 우선 사용한다.
  bool get isWaterShortage {
    final value = soil?.soilMoisturePercent;
    if (value == null) return false;

    return value <
        (watering?.shortageThresholdPercent ??
            IotThresholds.soilMoistureShortage);
  }

  // 급수 가능 여부 — 서버 판정을 우선 사용한다.
  bool get canWater {
    final serverDecision = watering?.canWater;
    if (serverDecision != null) return serverDecision;

    final value = soil?.soilMoisturePercent;
    return value == null || value < IotThresholds.soilMoistureTooWet;
  }

  // 수분이 충분해 급수가 차단된 상태
  bool get isTooWet => soil?.soilMoisturePercent != null && !canWater;

  // 급수 차단 사유 — 서버가 내려준 문구
  String? get waterBlockReason => watering?.blockReason;

  double? get soilMoisturePercent => soil?.soilMoisturePercent;
}

// 급수 가능 여부 — 서버가 자동화 설정과 최신 토양수분으로 계산해 내려준다.
class WateringGuard {
  final bool canWater;
  final String? blockReason;
  final double? shortageThresholdPercent;

  WateringGuard({
    required this.canWater,
    this.blockReason,
    this.shortageThresholdPercent,
  });

  // JSON 응답을 모델로 변환
  factory WateringGuard.fromJson(Map<String, dynamic> json) => WateringGuard(
    canWater: json['canWater'] ?? true,
    blockReason: json['blockReason'],
    shortageThresholdPercent: _toNullableDouble(
      json['shortageThresholdPercent'],
    ),
  );
}

// GrowSpaceInfo — IoT API 모델
class GrowSpaceInfo {
  final int growSpaceId;
  final String name;

  GrowSpaceInfo({required this.growSpaceId, required this.name});

  // JSON 응답을 모델로 변환
  factory GrowSpaceInfo.fromJson(Map<String, dynamic> json) => GrowSpaceInfo(
    growSpaceId: json['growSpaceId'] ?? 0,
    name: json['name'] ?? '',
  );
}

// EnvironmentData — IoT API 모델
class EnvironmentData {
  final int? sensorDataId;
  final double temperature;
  final double humidity;
  final double light;
  final String? measuredAt;

  EnvironmentData({
    this.sensorDataId,
    required this.temperature,
    required this.humidity,
    required this.light,
    this.measuredAt,
  });

  // JSON 응답을 모델로 변환
  factory EnvironmentData.fromJson(Map<String, dynamic> json) =>
      EnvironmentData(
        sensorDataId: json['sensorDataId'],
        temperature: (json['temperature'] ?? 0).toDouble(),
        humidity: (json['humidity'] ?? 0).toDouble(),
        light: (json['light'] ?? 0).toDouble(),
        measuredAt: json['measuredAt'],
      );
}

// SoilData — IoT API 모델
class SoilData {
  final int? sensorDataId;
  final int? soilMoistureRaw;
  final double? soilMoisturePercent;
  final String? measuredAt;

  SoilData({
    this.sensorDataId,
    this.soilMoistureRaw,
    this.soilMoisturePercent,
    this.measuredAt,
  });

  // JSON 응답을 모델로 변환
  factory SoilData.fromJson(Map<String, dynamic> json) => SoilData(
    sensorDataId: json['sensorDataId'],
    soilMoistureRaw: json['soilMoistureRaw'],
    soilMoisturePercent: _toNullableDouble(json['soilMoisturePercent']),
    measuredAt: json['measuredAt'],
  );
}

// nullable double 변환 — 파싱 실패 시 null 반환
double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

// PlantImageData — IoT API 모델
class PlantImageData {
  final int? plantImageId;
  final String imageUrl; // 매일 영상에서 캡처한 사진 — 서버 상대 경로("/images/...")
  final String? capturedAt;

  PlantImageData({
    this.plantImageId,
    required this.imageUrl,
    this.capturedAt,
  });

  // JSON 응답을 모델로 변환
  factory PlantImageData.fromJson(Map<String, dynamic> json) => PlantImageData(
    plantImageId: json['plantImageId'],
    imageUrl: json['imageUrl'] ?? '',
    capturedAt: json['capturedAt'],
  );
}

// IotCommandResponse — API 응답 모델
class IotCommandResponse {
  final int? commandId;
  final String commandType;
  final String commandStatus;

  IotCommandResponse({
    this.commandId,
    required this.commandType,
    required this.commandStatus,
  });

  // JSON 응답을 모델로 변환
  factory IotCommandResponse.fromJson(Map<String, dynamic> json) =>
      IotCommandResponse(
        commandId: json['commandId'],
        commandType: json['commandType'] ?? '',
        commandStatus: json['commandStatus'] ?? '',
      );
}

// SensorRefreshResponse — API 응답 모델
class SensorRefreshResponse {
  final int? userPlantId;
  final int? commandId;
  final String? commandType;
  final String? commandStatus;
  final String? target;
  final bool? alreadyPending;
  final String? duplicateReason;
  final List<String> refreshTargets;
  final List<String> excludedTargets;

  SensorRefreshResponse({
    this.userPlantId,
    this.commandId,
    this.commandType,
    this.commandStatus,
    this.target,
    this.alreadyPending,
    this.duplicateReason,
    this.refreshTargets = const [],
    this.excludedTargets = const [],
  });

  // JSON 응답을 모델로 변환
  factory SensorRefreshResponse.fromJson(Map<String, dynamic> json) {
    return SensorRefreshResponse(
      userPlantId: _toNullableInt(json['userPlantId']),
      commandId: _toNullableInt(json['commandId']),
      commandType: json['commandType']?.toString(),
      commandStatus: json['commandStatus']?.toString(),
      target: json['target']?.toString(),
      alreadyPending: json['alreadyPending'] is bool
          ? json['alreadyPending'] as bool
          : null,
      duplicateReason: json['duplicateReason']?.toString(),
      refreshTargets: _toStringList(json['refreshTargets']),
      excludedTargets: _toStringList(json['excludedTargets']),
    );
  }
}

// nullable int 변환 — 파싱 실패 시 null 반환
int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

// 문자열 리스트 변환 — List가 아니면 빈 목록 반환
List<String> _toStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

// 조명 상태 — 마지막으로 성공한 LIGHT_ON/LIGHT_OFF 명령 기준
class LightState {
  final bool on;
  final String? changedAt;

  LightState({required this.on, this.changedAt});

  factory LightState.fromJson(Map<String, dynamic> json) =>
      LightState(on: json['on'] == true, changedAt: json['changedAt']);
}

// 최근 장치 명령 요약
class CommandSummary {
  final int? commandId;
  final String commandType; // WATER, LIGHT_ON, LIGHT_OFF, SENSOR_REFRESH
  final String commandStatus; // PENDING, PROCESSING, SUCCESS, FAILED, CANCELLED
  final String? requestedAt;
  final String? completedAt;
  final String? resultMessage;

  CommandSummary({
    this.commandId,
    required this.commandType,
    required this.commandStatus,
    this.requestedAt,
    this.completedAt,
    this.resultMessage,
  });

  factory CommandSummary.fromJson(Map<String, dynamic> json) => CommandSummary(
    commandId: _toNullableInt(json['commandId']),
    commandType: json['commandType']?.toString() ?? '',
    commandStatus: json['commandStatus']?.toString() ?? '',
    requestedAt: json['requestedAt']?.toString(),
    completedAt: json['completedAt']?.toString(),
    resultMessage: json['resultMessage']?.toString(),
  );

  bool get isInProgress =>
      commandStatus == 'PENDING' || commandStatus == 'PROCESSING';
}

// 센서 기록 — GET /api/user-plants/{id}/iot/history 응답
class SensorHistory {
  final int hours;
  final List<SensorPoint> soilMoisture;
  final List<SensorPoint> temperature;
  final List<SensorPoint> humidity;
  final List<SensorPoint> light;

  SensorHistory({
    required this.hours,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.light,
  });

  factory SensorHistory.fromJson(Map<String, dynamic> json) {
    final soil = json['soil'] is List ? json['soil'] as List : const [];
    final env = json['environment'] is List
        ? json['environment'] as List
        : const [];

    List<SensorPoint> pick(List source, String key) => source
        .whereType<Map<String, dynamic>>()
        .map((e) => SensorPoint.tryParse(e['measuredAt'], e[key]))
        .whereType<SensorPoint>()
        .toList();

    return SensorHistory(
      hours: _toNullableInt(json['hours']) ?? 24,
      soilMoisture: pick(soil, 'soilMoisturePercent'),
      temperature: pick(env, 'temperature'),
      humidity: pick(env, 'humidity'),
      light: pick(env, 'light'),
    );
  }
}

// 그래프 한 점
class SensorPoint {
  final DateTime time;
  final double value;

  const SensorPoint(this.time, this.value);

  static SensorPoint? tryParse(dynamic time, dynamic value) {
    final parsedTime = time == null ? null : DateTime.tryParse(time.toString());
    final parsedValue = _toNullableDouble(value);
    if (parsedTime == null || parsedValue == null) return null;
    return SensorPoint(parsedTime, parsedValue);
  }
}

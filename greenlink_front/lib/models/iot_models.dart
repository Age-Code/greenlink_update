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

  IotLatestStatus({
    required this.userPlantId,
    this.growSpace,
    this.environment,
    this.soil,
    this.latestImage,
    this.watering,
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
      );

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
  final String imageUrl;
  final String? aiImageUrl; // AI 변환 이미지 (없을 수 있음)
  final String? capturedAt;

  PlantImageData({
    this.plantImageId,
    required this.imageUrl,
    this.aiImageUrl,
    this.capturedAt,
  });

  // JSON 응답을 모델로 변환
  factory PlantImageData.fromJson(Map<String, dynamic> json) => PlantImageData(
    plantImageId: json['plantImageId'],
    imageUrl: json['imageUrl'] ?? '',
    aiImageUrl: json['aiImageUrl'],
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

// 자동화 API 모델

// AutomationSettingModel — API 데이터 모델
class AutomationSettingModel {
  final int? automationSettingId;
  final int userPlantId;
  final bool autoWaterEnabled;
  final bool autoLightEnabled;
  final bool autoOptimizeEnabled;
  final bool wateringSafetyEnabled;
  final String decisionMode;
  final int minLearningDataCount;
  final double waterThresholdPercent;
  final int waterCooldownMinutes;
  final double lightOnThresholdLux;
  final double lightOffThresholdLux;
  final String lightStartTime;
  final String lightEndTime;
  final int lightCooldownMinutes;
  final String? createdAt;
  final String? modifiedAt;

  // 기본값은 Backend AutomationSetting.createDefault()와 동일하게 맞춘다.
  AutomationSettingModel({
    this.automationSettingId,
    required this.userPlantId,
    this.autoWaterEnabled = false,
    this.autoLightEnabled = false,
    this.autoOptimizeEnabled = false,
    this.wateringSafetyEnabled = false,
    this.decisionMode = 'HYBRID',
    this.minLearningDataCount = 30,
    this.waterThresholdPercent = 35.0,
    this.waterCooldownMinutes = 30,
    this.lightOnThresholdLux = 300.0,
    this.lightOffThresholdLux = 500.0,
    this.lightStartTime = '08:00:00',
    this.lightEndTime = '18:00:00',
    this.lightCooldownMinutes = 10,
    this.createdAt,
    this.modifiedAt,
  });

  // JSON 응답을 모델로 변환
  factory AutomationSettingModel.fromJson(Map<String, dynamic> json) {
    return AutomationSettingModel(
      automationSettingId: json['automationSettingId'],
      userPlantId: json['userPlantId'] ?? 0,
      autoWaterEnabled: json['autoWaterEnabled'] ?? false,
      autoLightEnabled: json['autoLightEnabled'] ?? false,
      autoOptimizeEnabled: json['autoOptimizeEnabled'] ?? false,
      wateringSafetyEnabled: json['wateringSafetyEnabled'] ?? false,
      decisionMode: json['decisionMode'] ?? 'HYBRID',
      minLearningDataCount: _parseInt(json['minLearningDataCount'], 30),
      waterThresholdPercent: _parseDouble(json['waterThresholdPercent'], 35.0),
      waterCooldownMinutes: _parseInt(json['waterCooldownMinutes'], 30),
      lightOnThresholdLux: _parseDouble(json['lightOnThresholdLux'], 300.0),
      lightOffThresholdLux: _parseDouble(json['lightOffThresholdLux'], 500.0),
      lightStartTime: json['lightStartTime'] ?? '08:00:00',
      lightEndTime: json['lightEndTime'] ?? '18:00:00',
      lightCooldownMinutes: _parseInt(json['lightCooldownMinutes'], 10),
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
    );
  }

  // 숫자 두 자리 문자열 변환
  static double _parseDouble(dynamic val, double def) {
    if (val == null) return def;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? def;
  }

  // 숫자 두 자리 문자열 변환
  static int _parseInt(dynamic val, int def) {
    if (val == null) return def;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? def;
  }
}

// AutomationModelModel — API 데이터 모델
class AutomationModelModel {
  final int? automationModelId;
  final int? userPlantId;
  final double? recommendedWaterThresholdPercent;
  final double? recommendedLightOnThresholdLux;
  final double? recommendedLightOffThresholdLux;
  final int? soilDataCount;
  final int? lightDataCount;
  final int? waterCommandCount;
  final double? avgDryRatePerHour;
  final double? avgWaterRecoveryPercent;
  final double? confidenceScore;
  final String? modelStatus;
  final String? trainedFrom;
  final String? trainedTo;
  final String? lastTrainedAt;
  final String? createdAt;
  final String? modifiedAt;

  AutomationModelModel({
    this.automationModelId,
    this.userPlantId,
    this.recommendedWaterThresholdPercent,
    this.recommendedLightOnThresholdLux,
    this.recommendedLightOffThresholdLux,
    this.soilDataCount,
    this.lightDataCount,
    this.waterCommandCount,
    this.avgDryRatePerHour,
    this.avgWaterRecoveryPercent,
    this.confidenceScore,
    this.modelStatus,
    this.trainedFrom,
    this.trainedTo,
    this.lastTrainedAt,
    this.createdAt,
    this.modifiedAt,
  });

  // JSON 응답을 모델로 변환
  factory AutomationModelModel.fromJson(Map<String, dynamic> json) {
    return AutomationModelModel(
      automationModelId: json['automationModelId'],
      userPlantId: json['userPlantId'],
      recommendedWaterThresholdPercent: _parseDoubleOpt(
        json['recommendedWaterThresholdPercent'],
      ),
      recommendedLightOnThresholdLux: _parseDoubleOpt(
        json['recommendedLightOnThresholdLux'],
      ),
      recommendedLightOffThresholdLux: _parseDoubleOpt(
        json['recommendedLightOffThresholdLux'],
      ),
      soilDataCount: json['soilDataCount'],
      lightDataCount: json['lightDataCount'],
      waterCommandCount: json['waterCommandCount'],
      avgDryRatePerHour: _parseDoubleOpt(json['avgDryRatePerHour']),
      avgWaterRecoveryPercent: _parseDoubleOpt(json['avgWaterRecoveryPercent']),
      confidenceScore: _parseDoubleOpt(json['confidenceScore']),
      modelStatus: json['modelStatus'],
      trainedFrom: json['trainedFrom'],
      trainedTo: json['trainedTo'],
      lastTrainedAt: json['lastTrainedAt'],
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
    );
  }

  // 숫자 두 자리 문자열 변환
  static double? _parseDoubleOpt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }
}

// AutomationLogModel — API 데이터 모델
class AutomationLogModel {
  final int automationLogId;
  final int userPlantId;
  final String automationType;
  final String triggerSensorType;
  final double? triggerValue;
  final double? thresholdValue;
  final int? commandId;
  final String message;
  final String createdAt;

  AutomationLogModel({
    required this.automationLogId,
    required this.userPlantId,
    required this.automationType,
    required this.triggerSensorType,
    this.triggerValue,
    this.thresholdValue,
    this.commandId,
    required this.message,
    required this.createdAt,
  });

  // JSON 응답을 모델로 변환
  factory AutomationLogModel.fromJson(Map<String, dynamic> json) {
    return AutomationLogModel(
      automationLogId: json['automationLogId'] ?? 0,
      userPlantId: json['userPlantId'] ?? 0,
      automationType: json['automationType'] ?? '',
      triggerSensorType: json['triggerSensorType'] ?? '',
      triggerValue: json['triggerValue'] != null
          ? (json['triggerValue'] as num).toDouble()
          : null,
      thresholdValue: json['thresholdValue'] != null
          ? (json['thresholdValue'] as num).toDouble()
          : null,
      commandId: json['commandId'],
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// 자동화 서비스 — 설정, 학습, 모델, 로그 API 호출

import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/automation_models.dart';

// AutomationService — Backend API 호출
class AutomationService {
  final ApiClient _client = ApiClient();

  // 자동화 설정 조회 API 호출
  Future<ApiResponse<AutomationSettingModel>> getAutomationSetting(
    int userPlantId,
  ) async {
    debugPrint('[AutomationService] 📋 자동화 설정 조회 (plantId=$userPlantId)');
    try {
      final response = await _client.get(ApiPaths.automation(userPlantId));
      final result = ApiResponse<AutomationSettingModel>.fromJson(
        response,
        (data) => AutomationSettingModel.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[AutomationService] ✅ 자동화 설정 조회 성공');
      } else {
        debugPrint('[AutomationService] ⚠️ 자동화 설정 조회 실패: ${result.message}');
      }
      return result;
    } catch (e) {
      debugPrint('[AutomationService] ❌ 자동화 설정 조회 예외: $e');
      return ApiResponse<AutomationSettingModel>(
        success: false,
        message: '자동화 설정을 불러오지 못했습니다. ($e)',
      );
    }
  }

  // 자동화 설정 수정 — payload 보정 후 PATCH 호출
  Future<ApiResponse<AutomationSettingModel>> updateAutomationSetting(
    int userPlantId,
    AutomationSettingModel setting, {
    String? lightStartTimeRaw,
    String? lightEndTimeRaw,
  }) async {
    final payload = buildAutomationPatchPayload(
      autoWaterEnabled: setting.autoWaterEnabled,
      autoLightEnabled: setting.autoLightEnabled,
      autoOptimizeEnabled: setting.autoOptimizeEnabled,
      wateringSafetyEnabled: setting.wateringSafetyEnabled,
      decisionMode: setting.decisionMode,
      minLearningDataCount: setting.minLearningDataCount,
      waterThresholdPercent: setting.waterThresholdPercent,
      waterCooldownMinutes: setting.waterCooldownMinutes,
      lightOnThresholdLux: setting.lightOnThresholdLux,
      lightOffThresholdLux: setting.lightOffThresholdLux,
      lightStartTime: lightStartTimeRaw ?? setting.lightStartTime,
      lightEndTime: lightEndTimeRaw ?? setting.lightEndTime,
      lightCooldownMinutes: setting.lightCooldownMinutes,
    );

    debugPrint(
      '[AutomationService] 📝 PATCH /automation payload: ${jsonEncode(payload)}',
    );

    try {
      final response = await _client.patch(
        ApiPaths.automation(userPlantId),
        body: payload,
      );

      if (response['success'] != true) {
        debugPrint(
          '[AutomationService] ❌ PATCH 실패 status=${response['status']} message=${response['message']}',
        );
        debugPrint('[AutomationService]   payload was: ${jsonEncode(payload)}');
      }

      final result = ApiResponse<AutomationSettingModel>.fromJson(
        response,
        (data) => AutomationSettingModel.fromJson(data),
      );
      debugPrint(
        '[AutomationService] ${result.success ? "✅" : "❌"} 자동화 설정 저장: ${result.message}',
      );
      return result;
    } catch (e) {
      debugPrint('[AutomationService] ❌ 자동화 설정 저장 예외: $e');
      debugPrint('[AutomationService]   payload was: ${jsonEncode(payload)}');
      return ApiResponse<AutomationSettingModel>(
        success: false,
        message: '자동화 설정 저장에 실패했습니다. ($e)',
      );
    }
  }

  // 최신 자동화 학습 모델 조회 — 없으면 null 반환
  Future<AutomationModelModel?> getLatestAutomationModel(
    int userPlantId,
  ) async {
    debugPrint('[AutomationService] 🤖 학습 모델 조회 (plantId=$userPlantId)');
    try {
      final response = await _client.get(ApiPaths.automationModel(userPlantId));
      if (response['success'] == true && response['data'] != null) {
        debugPrint('[AutomationService] ✅ 학습 모델 조회 성공');
        return AutomationModelModel.fromJson(response['data']);
      } else {
        debugPrint('[AutomationService] ℹ️ 학습 모델 없음: ${response['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('[AutomationService] ⚠️ 학습 모델 조회 예외 (무시됨): $e');
      return null;
    }
  }

  // 자동화 학습 실행 API 호출
  Future<ApiResponse<AutomationModelModel>> trainAutomationModel(
    int userPlantId,
  ) async {
    debugPrint('[AutomationService] 🏋️ 학습 실행 (plantId=$userPlantId)');
    try {
      final response = await _client.post(
        ApiPaths.automationTrain(userPlantId),
      );
      final result = ApiResponse<AutomationModelModel>.fromJson(
        response,
        (data) => AutomationModelModel.fromJson(data),
      );
      debugPrint(
        '[AutomationService] ${result.success ? "✅" : "❌"} 학습 실행: ${result.message}',
      );
      return result;
    } catch (e) {
      debugPrint('[AutomationService] ❌ 학습 실행 예외: $e');
      return ApiResponse<AutomationModelModel>(
        success: false,
        message: '학습 실행에 실패했습니다. ($e)',
      );
    }
  }

  // 자동화 로그 조회 API 호출
  Future<ApiResponse<List<AutomationLogModel>>> getAutomationLogs(
    int userPlantId,
  ) async {
    debugPrint('[AutomationService] 📜 자동화 로그 조회 (plantId=$userPlantId)');
    try {
      final response = await _client.get(ApiPaths.automationLogs(userPlantId));
      if (response['success'] == true) {
        final rawList = response['data'];
        if (rawList == null) {
          return ApiResponse<List<AutomationLogModel>>(
            success: true,
            message: '로그 없음',
            data: [],
          );
        }
        final list = (rawList as List)
            .map((e) => AutomationLogModel.fromJson(e))
            .toList();
        debugPrint('[AutomationService] ✅ 자동화 로그 조회 성공 (${list.length}건)');
        return ApiResponse<List<AutomationLogModel>>(
          success: true,
          message: response['message'] ?? '',
          data: list,
        );
      } else {
        debugPrint(
          '[AutomationService] ⚠️ 자동화 로그 조회 실패: ${response['message']}',
        );
        return ApiResponse<List<AutomationLogModel>>(
          success: false,
          message: response['message'] ?? '',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('[AutomationService] ❌ 자동화 로그 조회 예외: $e');
      return ApiResponse<List<AutomationLogModel>>(
        success: false,
        message: '자동화 로그를 불러오지 못했습니다. ($e)',
        data: [],
      );
    }
  }
}

// 서버 시간값 변환 — HH:mm은 HH:mm:ss로 보정
String toServerTimeValue(String? value, {String defaultValue = '00:00:00'}) {
  if (value == null || value.trim().isEmpty) return defaultValue;
  final text = value.trim();
  if (text.length == 5) return '$text:00';
  return text;
}

// 시간 입력값 변환 — HH:mm:ss를 HH:mm으로 축약
String toTimeInputValue(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

// double 파싱 — 실패 시 기본값 반환
double parseDoubleOrDefault(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  if (text.isEmpty) return defaultValue;
  return double.tryParse(text) ?? defaultValue;
}

// int 파싱 — 실패 시 기본값 반환
int parseIntOrDefault(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return defaultValue;
  return int.tryParse(text) ?? defaultValue;
}

// 자동화 PATCH payload 생성 — 수치와 시간값 보정
Map<String, dynamic> buildAutomationPatchPayload({
  required bool autoWaterEnabled,
  required bool autoLightEnabled,
  required bool autoOptimizeEnabled,
  required bool wateringSafetyEnabled,
  required String decisionMode,
  required dynamic minLearningDataCount,
  required dynamic waterThresholdPercent,
  required dynamic waterCooldownMinutes,
  required dynamic lightOnThresholdLux,
  required dynamic lightOffThresholdLux,
  required String? lightStartTime,
  required String? lightEndTime,
  required dynamic lightCooldownMinutes,
}) {
  final lightOn = parseDoubleOrDefault(lightOnThresholdLux, 300.0);
  var lightOff = parseDoubleOrDefault(lightOffThresholdLux, 500.0);
  if (lightOff <= lightOn) lightOff = lightOn + 50.0;

  final minDataCount = parseIntOrDefault(minLearningDataCount, 30);

  return {
    'autoWaterEnabled': autoWaterEnabled,
    'autoLightEnabled': autoLightEnabled,
    'autoOptimizeEnabled': autoOptimizeEnabled,
    'wateringSafetyEnabled': wateringSafetyEnabled,
    'decisionMode': decisionMode.isEmpty ? 'HYBRID' : decisionMode,
    'minLearningDataCount': minDataCount < 1 ? 30 : minDataCount,
    'waterThresholdPercent': parseDoubleOrDefault(waterThresholdPercent, 35.0),
    'waterCooldownMinutes': parseIntOrDefault(waterCooldownMinutes, 30),
    'lightOnThresholdLux': lightOn,
    'lightOffThresholdLux': lightOff,
    'lightStartTime': toServerTimeValue(
      lightStartTime,
      defaultValue: '00:00:00',
    ),
    'lightEndTime': toServerTimeValue(lightEndTime, defaultValue: '23:59:00'),
    'lightCooldownMinutes': parseIntOrDefault(lightCooldownMinutes, 10),
  };
}

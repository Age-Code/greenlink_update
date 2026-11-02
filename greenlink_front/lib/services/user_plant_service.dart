// 사용자 식물 서비스 — 식재, 조회, 수확 API 호출

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/user_plant_models.dart';

// UserPlantService — Backend API 호출
class UserPlantService {
  final ApiClient _client = ApiClient();

  // 사용자 식물 목록 조회 API 호출
  Future<ApiResponse<List<UserPlantSummary>>> getUserPlants({String? status}) async {
    debugPrint('[UserPlantService] 🌱 내 식물 목록 조회 (status=$status)');
    try {
      final path = '${ApiPaths.userPlants}${status != null ? '?status=$status' : ''}';
      final response = await _client.get(path);
      final result = ApiResponse<List<UserPlantSummary>>.fromJson(
        response,
        (data) => (data as List).map((i) => UserPlantSummary.fromJson(i)).toList(),
      );
      if (result.success) {
        debugPrint('[UserPlantService] ✅ 식물 ${result.data?.length ?? 0}개');
      }
      return result;
    } catch (e) {
      debugPrint('[UserPlantService] ❌ 목록 조회 예외: $e');
      return ApiResponse<List<UserPlantSummary>>(success: false, message: '내 식물 목록을 불러오지 못했습니다: $e');
    }
  }

  // 사용자 식물 상세 조회 API 호출
  Future<ApiResponse<UserPlantDetail>> getUserPlantDetail(int userPlantId) async {
    debugPrint('[UserPlantService] 🔍 식물 상세 조회 (id=$userPlantId)');
    try {
      final response = await _client.get(ApiPaths.userPlantDetail(userPlantId));
      final result = ApiResponse<UserPlantDetail>.fromJson(
        response,
        (data) => UserPlantDetail.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[UserPlantService] ✅ nickname=${result.data!.nickname}, status=${result.data!.status}');
        debugPrint('[UserPlantService]   equippedPot=${result.data!.equippedPot?.name ?? "없음"}');
      }
      return result;
    } catch (e) {
      debugPrint('[UserPlantService] ❌ 상세 조회 예외: $e');
      return ApiResponse<UserPlantDetail>(success: false, message: '식물 정보를 불러오지 못했습니다: $e');
    }
  }

  // 씨앗 심기 API 호출
  Future<ApiResponse<UserPlantSummary>> plantSeed(int userItemId, String nickname) async {
    debugPrint('[UserPlantService] 🌱 씨앗 심기 (userItemId=$userItemId, nickname=$nickname)');
    try {
      final response = await _client.post(
        ApiPaths.userPlants,
        body: {'userItemId': userItemId, 'nickname': nickname},
      );
      final result = ApiResponse<UserPlantSummary>.fromJson(
        response,
        (data) => UserPlantSummary.fromJson(data),
      );
      if (result.success) {
        debugPrint('[UserPlantService] ✅ 씨앗 심기 성공 — userPlantId=${result.data?.userPlantId}');
      }
      return result;
    } catch (e) {
      debugPrint('[UserPlantService] ❌ 씨앗 심기 예외: $e');
      return ApiResponse<UserPlantSummary>(success: false, message: '씨앗 심기에 실패했습니다: $e');
    }
  }

  // 식물 별명 수정 API 호출
  Future<ApiResponse<void>> updateUserPlantNickname(int userPlantId, String nickname) async {
    debugPrint('[UserPlantService] ✏️ 이름 수정 (id=$userPlantId, nickname=$nickname)');
    try {
      final response = await _client.patch(
        ApiPaths.userPlantDetail(userPlantId),
        body: {'nickname': nickname},
      );
      return ApiResponse<void>(
        success: response['success'] ?? false,
        message: response['message'] ?? '',
      );
    } catch (e) {
      debugPrint('[UserPlantService] ❌ 이름 수정 예외: $e');
      return ApiResponse<void>(success: false, message: '이름 수정에 실패했습니다: $e');
    }
  }

  // 식물 수확 API 호출
  Future<ApiResponse<void>> harvestUserPlant(int userPlantId) async {
    debugPrint('[UserPlantService] 🌾 수확 (id=$userPlantId)');
    try {
      final response = await _client.post(ApiPaths.harvestUserPlant(userPlantId));
      final success = response['success'] ?? false;
      debugPrint('[UserPlantService] ${success ? "✅ 수확 성공" : "❌ 수확 실패"}: ${response['message']}');
      return ApiResponse<void>(
        success: success,
        message: response['message'] ?? '',
      );
    } catch (e) {
      debugPrint('[UserPlantService] ❌ 수확 예외: $e');
      return ApiResponse<void>(success: false, message: '수확에 실패했습니다: $e');
    }
  }
}

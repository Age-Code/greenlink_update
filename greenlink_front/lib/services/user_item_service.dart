// 사용자 아이템 서비스 — 인벤토리, 화분 장착, 영양제 사용 API 호출

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/user_item_models.dart';

// UserItemService — Backend API 호출
class UserItemService {
  final ApiClient _client = ApiClient();

  // 사용자 아이템 목록 조회 API 호출
  Future<ApiResponse<List<UserItemGroup>>> getUserItems({String? itemType, String? status}) async {
    debugPrint('[UserItemService] 🎒 인벤토리 조회 (itemType=$itemType, status=$status)');
    try {
      final queryParams = <String>[];
      if (itemType != null) queryParams.add('itemType=$itemType');
      if (status != null) queryParams.add('status=$status');
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final path = '${ApiPaths.userItems}$queryString';
      final response = await _client.get(path);
      final result = ApiResponse<List<UserItemGroup>>.fromJson(
        response,
        (data) => (data as List).map((i) => UserItemGroup.fromJson(i)).toList(),
      );
      if (result.success) {
        debugPrint('[UserItemService] ✅ 아이템 그룹 ${result.data?.length ?? 0}개');
      }
      return result;
    } catch (e) {
      debugPrint('[UserItemService] ❌ 인벤토리 조회 예외: $e');
      return ApiResponse<List<UserItemGroup>>(success: false, message: '인벤토리를 불러오지 못했습니다: $e');
    }
  }

  // 화분 장착 API 호출
  Future<ApiResponse<Map<String, dynamic>>> equipPot(int userItemId, int userPlantId) async {
    debugPrint('[UserItemService] 🪴 화분 장착 (itemId=$userItemId, plantId=$userPlantId)');
    try {
      final response = await _client.post(
        ApiPaths.equipPot(userItemId),
        body: {'userPlantId': userPlantId},
      );
      debugPrint('[UserItemService] ${response['success'] == true ? "✅ 장착 성공" : "❌ 장착 실패"}: ${response['message']}');
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[UserItemService] ❌ 화분 장착 예외: $e');
      return ApiResponse<Map<String, dynamic>>(success: false, message: '화분 장착에 실패했습니다: $e');
    }
  }

  // 영양제 사용 API 호출
  Future<ApiResponse<Map<String, dynamic>>> useNutrient(int userItemId, int userPlantId) async {
    debugPrint('[UserItemService] 💧 영양제 사용 (itemId=$userItemId, plantId=$userPlantId)');
    try {
      final response = await _client.post(
        ApiPaths.useNutrient(userItemId),
        body: {'userPlantId': userPlantId},
      );
      debugPrint('[UserItemService] ${response['success'] == true ? "✅ 사용 성공" : "❌ 사용 실패"}: ${response['message']}');
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[UserItemService] ❌ 영양제 사용 예외: $e');
      return ApiResponse<Map<String, dynamic>>(success: false, message: '영양제 사용에 실패했습니다: $e');
    }
  }
}

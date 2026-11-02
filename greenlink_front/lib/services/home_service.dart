// 홈 서비스 — 홈 데이터 API 호출

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/home_models.dart';

// HomeService — Backend API 호출
class HomeService {
  final ApiClient _client = ApiClient();

  // 홈 데이터 조회 API 호출
  Future<ApiResponse<HomeResponse>> getHomeData() async {
    debugPrint('[HomeService] 🏠 홈 데이터 조회');
    try {
      final response = await _client.get(ApiPaths.home);
      final result = ApiResponse<HomeResponse>.fromJson(
        response,
        (data) => HomeResponse.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[HomeService] ✅ nickname=${result.data!.user.nickname}');
        debugPrint('[HomeService]   mainUserPlant=${result.data!.mainUserPlant?.nickname ?? "null"}');
      }
      return result;
    } catch (e) {
      debugPrint('[HomeService] ❌ 홈 조회 예외: $e');
      return ApiResponse<HomeResponse>(success: false, message: '홈 데이터를 불러오지 못했습니다: $e');
    }
  }
}

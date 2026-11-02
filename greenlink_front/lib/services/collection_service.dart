// 도감 서비스 — 도감 목록과 상세 API 호출

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/collection_models.dart';

// CollectionService — Backend API 호출
class CollectionService {
  final ApiClient _client = ApiClient();

  // 도감 목록 조회 API 호출
  Future<ApiResponse<List<CollectionPlant>>> getCollections() async {
    debugPrint('[CollectionService] 📚 도감 목록 조회');
    try {
      final response = await _client.get(ApiPaths.collections);
      final result = ApiResponse<List<CollectionPlant>>.fromJson(
        response,
        (data) => (data as List).map((i) => CollectionPlant.fromJson(i)).toList(),
      );
      if (result.success) {
        final collected = result.data?.where((p) => p.collected).length ?? 0;
        final total = result.data?.length ?? 0;
        debugPrint('[CollectionService] ✅ 도감 $total개 (수집: $collected개)');
      }
      return result;
    } catch (e) {
      debugPrint('[CollectionService] ❌ 도감 조회 예외: $e');
      return ApiResponse<List<CollectionPlant>>(success: false, message: '도감을 불러오지 못했습니다: $e');
    }
  }

  // 도감 상세 조회 API 호출
  Future<ApiResponse<CollectionDetail>> getCollectionDetail(int plantId) async {
    debugPrint('[CollectionService] 🔍 도감 상세 조회 (plantId=$plantId)');
    try {
      final response = await _client.get(ApiPaths.collectionDetail(plantId));
      final result = ApiResponse<CollectionDetail>.fromJson(
        response,
        (data) => CollectionDetail.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[CollectionService] ✅ name=${result.data!.name}, collected=${result.data!.collected}');
        debugPrint('[CollectionService]   harvestedPlants=${result.data!.harvestedPlants.length}개');
      }
      return result;
    } catch (e) {
      debugPrint('[CollectionService] ❌ 도감 상세 조회 예외: $e');
      return ApiResponse<CollectionDetail>(success: false, message: '도감 상세 정보를 불러오지 못했습니다: $e');
    }
  }
}

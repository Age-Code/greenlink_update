// 퀘스트 서비스 — 퀘스트 조회와 보상 수령 API 호출

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/quest_models.dart';

// QuestService — Backend API 호출
class QuestService {
  final ApiClient _client = ApiClient();

  // 사용자 퀘스트 목록 조회 API 호출
  Future<ApiResponse<List<UserQuestSummary>>> getUserQuests({String? questType, String? status}) async {
    debugPrint('[QuestService] 📋 퀘스트 목록 조회 (type=$questType, status=$status)');
    try {
      final queryParams = <String>[];
      if (questType != null && questType != 'ALL') queryParams.add('questType=$questType');
      if (status != null && status != 'ALL') queryParams.add('status=$status');
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final path = '${ApiPaths.userQuests}$queryString';
      final response = await _client.get(path);
      final result = ApiResponse<List<UserQuestSummary>>.fromJson(
        response,
        (data) => (data as List).map((q) => UserQuestSummary.fromJson(q)).toList(),
      );
      if (result.success) {
        final achievable = result.data?.where((q) => q.status == 'ACHIEVABLE').length ?? 0;
        debugPrint('[QuestService] ✅ 퀘스트 ${result.data?.length ?? 0}개 (보상 가능: $achievable개)');
      }
      return result;
    } catch (e) {
      debugPrint('[QuestService] ❌ 퀘스트 조회 예외: $e');
      return ApiResponse<List<UserQuestSummary>>(success: false, message: '퀘스트를 불러오지 못했습니다: $e');
    }
  }

  // 사용자 퀘스트 상세 조회 API 호출
  Future<ApiResponse<UserQuestDetail>> getUserQuestDetail(int userQuestId) async {
    debugPrint('[QuestService] 🔍 퀘스트 상세 조회 (id=$userQuestId)');
    try {
      final response = await _client.get(ApiPaths.userQuestDetail(userQuestId));
      final result = ApiResponse<UserQuestDetail>.fromJson(
        response,
        (data) => UserQuestDetail.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[QuestService] ✅ title=${result.data!.title}, status=${result.data!.status}');
        debugPrint('[QuestService]   rewardItem=${result.data!.rewardItem?.name ?? "없음"}');
      }
      return result;
    } catch (e) {
      debugPrint('[QuestService] ❌ 퀘스트 상세 조회 예외: $e');
      return ApiResponse<UserQuestDetail>(success: false, message: '퀘스트 상세를 불러오지 못했습니다: $e');
    }
  }

  // 퀘스트 보상 수령 API 호출
  Future<ApiResponse<QuestRewardResponse>> receiveReward(int userQuestId) async {
    debugPrint('[QuestService] 🎁 보상 수령 (id=$userQuestId)');
    try {
      final response = await _client.post(ApiPaths.receiveQuestReward(userQuestId));
      final result = ApiResponse<QuestRewardResponse>.fromJson(
        response,
        (data) => QuestRewardResponse.fromJson(data),
      );
      if (result.success && result.data != null) {
        debugPrint('[QuestService] ✅ 보상 수령 성공: ${result.data!.reward.itemName} ${result.data!.reward.quantity}개');
      }
      return result;
    } catch (e) {
      debugPrint('[QuestService] ❌ 보상 수령 예외: $e');
      return ApiResponse<QuestRewardResponse>(success: false, message: '보상 수령에 실패했습니다: $e');
    }
  }
}

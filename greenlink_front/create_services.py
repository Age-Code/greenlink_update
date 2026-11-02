import os

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

# home_service.dart
home_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/home_models.dart';

class HomeService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<HomeResponse>> getHomeData() async {
    try {
      final response = await _client.get(ApiPaths.home);
      return ApiResponse<HomeResponse>.fromJson(
        response,
        (data) => HomeResponse.fromJson(data)
      );
    } catch (e) {
      return ApiResponse<HomeResponse>(success: false, message: '홈 데이터 조회 실패: $e');
    }
  }
}
"""

# user_item_service.dart
user_item_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/user_item_models.dart';

class UserItemService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<UserItemGroup>>> getUserItems({String? itemType, String? status}) async {
    try {
      final queryParams = <String>[];
      if (itemType != null) queryParams.add('itemType=$itemType');
      if (status != null) queryParams.add('status=$status');
      
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final path = '${ApiPaths.userItems}$queryString';
      final response = await _client.get(path);
      
      return ApiResponse<List<UserItemGroup>>.fromJson(
        response,
        (data) => (data as List).map((i) => UserItemGroup.fromJson(i)).toList()
      );
    } catch (e) {
      return ApiResponse<List<UserItemGroup>>(success: false, message: '아이템 조회 실패: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> equipPot(int userItemId, int userPlantId) async {
    try {
      final response = await _client.post(ApiPaths.equipPot(userItemId), body: {'userPlantId': userPlantId});
      return ApiResponse<Map<String, dynamic>>.fromJson(response, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: '화분 장착 실패: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> useNutrient(int userItemId, int userPlantId) async {
    try {
      final response = await _client.post(ApiPaths.useNutrient(userItemId), body: {'userPlantId': userPlantId});
      return ApiResponse<Map<String, dynamic>>.fromJson(response, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: '영양제 사용 실패: $e');
    }
  }
}
"""

# user_plant_service.dart
user_plant_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/user_plant_models.dart';

class UserPlantService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<UserPlantSummary>>> getUserPlants({String? status}) async {
    try {
      final path = '${ApiPaths.userPlants}${status != null ? '?status=$status' : ''}';
      final response = await _client.get(path);
      
      return ApiResponse<List<UserPlantSummary>>.fromJson(
        response,
        (data) => (data as List).map((i) => UserPlantSummary.fromJson(i)).toList()
      );
    } catch (e) {
      return ApiResponse<List<UserPlantSummary>>(success: false, message: '내 식물 목록 조회 실패: $e');
    }
  }

  Future<ApiResponse<UserPlantDetail>> getUserPlantDetail(int userPlantId) async {
    try {
      final response = await _client.get(ApiPaths.userPlantDetail(userPlantId));
      return ApiResponse<UserPlantDetail>.fromJson(response, (data) => UserPlantDetail.fromJson(data));
    } catch (e) {
      return ApiResponse<UserPlantDetail>(success: false, message: '내 식물 상세 조회 실패: $e');
    }
  }

  Future<ApiResponse<UserPlantSummary>> plantSeed(int userItemId, String nickname) async {
    try {
      final response = await _client.post(
        ApiPaths.userPlants,
        body: {'userItemId': userItemId, 'nickname': nickname}
      );
      return ApiResponse<UserPlantSummary>.fromJson(response, (data) => UserPlantSummary.fromJson(data));
    } catch (e) {
      return ApiResponse<UserPlantSummary>(success: false, message: '씨앗 심기 실패: $e');
    }
  }

  Future<ApiResponse<void>> updateUserPlantNickname(int userPlantId, String nickname) async {
    try {
      final response = await _client.patch(
        ApiPaths.userPlantDetail(userPlantId),
        body: {'nickname': nickname}
      );
      return ApiResponse<void>.fromJson(response, (_) => null);
    } catch (e) {
      return ApiResponse<void>(success: false, message: '이름 수정 실패: $e');
    }
  }

  Future<ApiResponse<void>> harvestUserPlant(int userPlantId) async {
    try {
      final response = await _client.post(ApiPaths.harvestUserPlant(userPlantId));
      return ApiResponse<void>.fromJson(response, (_) => null);
    } catch (e) {
      return ApiResponse<void>(success: false, message: '수확 실패: $e');
    }
  }
}
"""

# collection_service.dart
collection_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/collection_models.dart';

class CollectionService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<CollectionPlant>>> getCollections() async {
    try {
      final response = await _client.get(ApiPaths.collections);
      return ApiResponse<List<CollectionPlant>>.fromJson(
        response,
        (data) => (data as List).map((i) => CollectionPlant.fromJson(i)).toList()
      );
    } catch (e) {
      return ApiResponse<List<CollectionPlant>>(success: false, message: '도감 조회 실패: $e');
    }
  }

  Future<ApiResponse<CollectionDetail>> getCollectionDetail(int plantId) async {
    try {
      final response = await _client.get(ApiPaths.collectionDetail(plantId));
      return ApiResponse<CollectionDetail>.fromJson(response, (data) => CollectionDetail.fromJson(data));
    } catch (e) {
      return ApiResponse<CollectionDetail>(success: false, message: '도감 상세 조회 실패: $e');
    }
  }
}
"""

# quest_service.dart
quest_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/quest_models.dart';

class QuestService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<UserQuestSummary>>> getUserQuests({String? questType, String? status}) async {
    try {
      final queryParams = <String>[];
      if (questType != null && questType != 'ALL') queryParams.add('questType=$questType');
      if (status != null && status != 'ALL') queryParams.add('status=$status');
      
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final path = '${ApiPaths.userQuests}$queryString';
      final response = await _client.get(path);
      
      return ApiResponse<List<UserQuestSummary>>.fromJson(
        response,
        (data) => (data as List).map((q) => UserQuestSummary.fromJson(q)).toList()
      );
    } catch (e) {
      return ApiResponse<List<UserQuestSummary>>(success: false, message: '퀘스트 조회 실패: $e');
    }
  }

  Future<ApiResponse<UserQuestDetail>> getUserQuestDetail(int userQuestId) async {
    try {
      final response = await _client.get(ApiPaths.userQuestDetail(userQuestId));
      return ApiResponse<UserQuestDetail>.fromJson(response, (data) => UserQuestDetail.fromJson(data));
    } catch (e) {
      return ApiResponse<UserQuestDetail>(success: false, message: '퀘스트 상세 조회 실패: $e');
    }
  }

  Future<ApiResponse<QuestRewardResponse>> receiveReward(int userQuestId) async {
    try {
      final response = await _client.post(ApiPaths.receiveQuestReward(userQuestId));
      return ApiResponse<QuestRewardResponse>.fromJson(response, (data) => QuestRewardResponse.fromJson(data));
    } catch (e) {
      return ApiResponse<QuestRewardResponse>(success: false, message: '보상 수령 실패: $e');
    }
  }
}
"""

# attend_service.dart
attend_service = """import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/constants/api_paths.dart';
import '../models/attend_models.dart';

class AttendService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<AttendMonth>> getAttends({required int year, required int month}) async {
    try {
      final path = '${ApiPaths.attends}?year=$year&month=$month';
      final response = await _client.get(path);
      return ApiResponse<AttendMonth>.fromJson(response, (data) => AttendMonth.fromJson(data));
    } catch (e) {
      return ApiResponse<AttendMonth>(success: false, message: '출석 기록 조회 실패: $e');
    }
  }

  Future<ApiResponse<AttendTodayResponse>> attendToday() async {
    try {
      final response = await _client.post(ApiPaths.attendToday);
      return ApiResponse<AttendTodayResponse>.fromJson(response, (data) => AttendTodayResponse.fromJson(data));
    } catch (e) {
      return ApiResponse<AttendTodayResponse>(success: false, message: '출석 체크 실패: $e');
    }
  }
}
"""

def write_services():
    create_file('lib/services/home_service.dart', home_service)
    create_file('lib/services/user_item_service.dart', user_item_service)
    create_file('lib/services/user_plant_service.dart', user_plant_service)
    create_file('lib/services/collection_service.dart', collection_service)
    create_file('lib/services/quest_service.dart', quest_service)
    create_file('lib/services/attend_service.dart', attend_service)

write_services()
print("Services created.")

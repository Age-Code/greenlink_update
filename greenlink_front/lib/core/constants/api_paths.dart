// API 경로 상수

// ApiPaths — API 경로 상수
class ApiPaths {
  // Auth
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String kakaoLogin = '/auth/oauth/kakao';
  static const String googleLogin = '/auth/oauth/google';

  // User
  static const String userMe = '/users/me';
  static const String changePassword = '/users/me/password';
  static const String withdraw = '/users/me';
  static const String logout = '/users/me/logout';

  // Home
  static const String home = '/home';

  // UserItem
  static const String userItems = '/user-items';
  // 화분 장착 API 호출
  static String equipPot(int userItemId) => '/user-items/$userItemId/equip-pot';
  // 화분 해제 경로 생성
  static String unequipPot(int userItemId) =>
      '/user-items/$userItemId/unequip-pot';
  // 영양제 사용 API 호출
  static String useNutrient(int userItemId) =>
      '/user-items/$userItemId/use-nutrient';

  // UserPlant
  static const String userPlants = '/user-plants';
  // 식물 상세 경로 생성
  static String userPlantDetail(int userPlantId) => '/user-plants/$userPlantId';
  // 식물 수확 API 호출
  static String harvestUserPlant(int userPlantId) =>
      '/user-plants/$userPlantId/harvest';

  // Collection
  static const String collections = '/collections';
  // 도감 상세 경로 생성
  static String collectionDetail(int plantId) => '/collections/$plantId';

  // Quest
  static const String userQuests = '/user-quests';
  // 퀘스트 상세 경로 생성
  static String userQuestDetail(int userQuestId) => '/user-quests/$userQuestId';
  // 퀘스트 보상 수령 경로 생성
  static String receiveQuestReward(int userQuestId) =>
      '/user-quests/$userQuestId/reward';

  // Attend
  static const String attends = '/attends';
  static const String attendToday = '/attends/today';

  // 최신 IoT 상태 경로 생성
  static String iotLatest(int userPlantId) =>
      '/user-plants/$userPlantId/iot/latest';
  // 센서 새로고침 경로 생성
  static String iotRefresh(int userPlantId) =>
      '/user-plants/$userPlantId/iot/refresh';
  // 물주기 명령 경로 생성
  static String iotWater(int userPlantId) =>
      '/user-plants/$userPlantId/iot/water';
  // 조명 켜기 명령 경로 생성
  static String iotLightOn(int userPlantId) =>
      '/user-plants/$userPlantId/iot/light/on';
  // 조명 끄기 명령 경로 생성
  static String iotLightOff(int userPlantId) =>
      '/user-plants/$userPlantId/iot/light/off';

  // 자동화 설정 경로 생성
  static String automation(int userPlantId) =>
      '/user-plants/$userPlantId/automation';
  // 자동화 학습 경로 생성
  static String automationTrain(int userPlantId) =>
      '/user-plants/$userPlantId/automation/train';
  // 자동화 모델 경로 생성
  static String automationModel(int userPlantId) =>
      '/user-plants/$userPlantId/automation/model';
  // 자동화 로그 경로 생성
  static String automationLogs(int userPlantId) =>
      '/user-plants/$userPlantId/automation/logs';
}

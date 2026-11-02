// Enum 라벨 매핑 유틸리티

// EnumLabelMapper — Enum 라벨 매핑 유틸리티
class EnumLabelMapper {
  // 아이템 타입 라벨 반환
  static String itemType(String? type) {
    switch (type) {
      case 'SEED': return '씨앗';
      case 'POT': return '화분';
      case 'NUTRIENT': return '영양제';
      default: return type ?? '';
    }
  }

  // 사용자 아이템 상태 라벨 반환
  static String userItemStatus(String? status) {
    switch (status) {
      case 'OWNED': return '보유 중';
      case 'EQUIPPED': return '장착 중';
      case 'USED': return '사용 완료';
      default: return status ?? '';
    }
  }

  // 사용자 식물 상태 라벨 반환
  static String userPlantStatus(String? status) {
    switch (status) {
      case 'GROWING': return '자라는 중';
      case 'HARVESTABLE': return '수확 가능';
      case 'HARVESTED': return '수확 완료';
      default: return status ?? '';
    }
  }

  // 퀘스트 타입 라벨 반환
  static String questType(String? type) {
    switch (type) {
      case 'DAILY': return '오늘의 약속';
      case 'WEEKLY': return '이번 주 약속';
      case 'MONTHLY': return '이번 달 약속';
      case 'ACHIEVEMENT': return '도전 기록';
      default: return type ?? '';
    }
  }

  // 사용자 퀘스트 상태 라벨 반환
  static String userQuestStatus(String? status) {
    switch (status) {
      case 'IN_PROGRESS': return '진행 중';
      case 'ACHIEVABLE': return '보상 가능';
      case 'COMPLETED': return '완료';
      case 'EXPIRED': return '기간 만료';
      default: return status ?? '';
    }
  }

  // 퀘스트 목표 타입 라벨 반환
  static String targetType(String? type) {
    switch (type) {
      case 'ATTEND': return '출석';
      case 'WATERING': return '물주기';
      case 'GROW_PLANT': return '식물 키우기';
      case 'HARVEST': return '수확';
      default: return type ?? '';
    }
  }
}

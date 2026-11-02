// 사용자 식물 API 모델

// UserPlantSummary — 사용자 식물 API 모델
class UserPlantSummary {
  final int userPlantId;
  final int plantId;
  final String plantName;
  final String nickname;
  final String status;
  final String? plantedAt;
  final int? daysAfterPlanting;
  final int? remainingDays;
  final String? imageUrl;

  UserPlantSummary({
    required this.userPlantId, required this.plantId, required this.plantName,
    required this.nickname, required this.status, this.plantedAt,
    this.daysAfterPlanting, this.remainingDays, this.imageUrl,
  });

  // JSON 응답을 모델로 변환
  factory UserPlantSummary.fromJson(Map<String, dynamic> json) => UserPlantSummary(
    userPlantId: json['userPlantId'] ?? 0,
    plantId: json['plantId'] ?? 0,
    plantName: json['plantName'] ?? '',
    nickname: json['nickname'] ?? '',
    status: json['status'] ?? 'GROWING',
    plantedAt: json['plantedAt'],
    daysAfterPlanting: json['daysAfterPlanting'],
    remainingDays: json['remainingDays'],
    imageUrl: json['imageUrl'],
  );
}

// UserPlantDetail — 사용자 식물 API 모델
class UserPlantDetail {
  final int userPlantId;
  final int plantId;
  final String plantName;
  final String nickname;
  final String? imageUrl;
  final String status;
  final String? plantedAt;
  final String? harvestedAt;
  final int? daysAfterPlanting;
  final int? remainingDays;
  final EquippedPot? equippedPot;

  UserPlantDetail({
    required this.userPlantId, required this.plantId, required this.plantName,
    required this.nickname, this.imageUrl, required this.status,
    this.plantedAt, this.harvestedAt, this.daysAfterPlanting,
    this.remainingDays, this.equippedPot,
  });

  // JSON 응답을 모델로 변환
  factory UserPlantDetail.fromJson(Map<String, dynamic> json) => UserPlantDetail(
    userPlantId: json['userPlantId'] ?? 0,
    plantId: json['plantId'] ?? 0,
    plantName: json['plantName'] ?? '',
    nickname: json['nickname'] ?? '',
    imageUrl: json['imageUrl'],
    status: json['status'] ?? 'GROWING',
    plantedAt: json['plantedAt'],
    harvestedAt: json['harvestedAt'],
    daysAfterPlanting: json['daysAfterPlanting'],
    remainingDays: json['remainingDays'],
    equippedPot: json['equippedPot'] != null ? EquippedPot.fromJson(json['equippedPot']) : null,
  );
}

// EquippedPot — 사용자 식물 API 모델
class EquippedPot {
  final int userItemId;
  final int itemId;
  final String name;
  final String? imageUrl;

  EquippedPot({required this.userItemId, required this.itemId, required this.name, this.imageUrl});

  // JSON 응답을 모델로 변환
  factory EquippedPot.fromJson(Map<String, dynamic> json) => EquippedPot(
    userItemId: json['userItemId'] ?? 0,
    itemId: json['itemId'] ?? 0,
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

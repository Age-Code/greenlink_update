// 도감 API 모델

// CollectionPlant — 도감 API 모델
class CollectionPlant {
  final int plantId;
  final String name;
  final String category;
  final String? imageUrl;
  final bool collected;
  final int harvestCount;
  final String? firstHarvestedAt;

  CollectionPlant({
    required this.plantId, required this.name, required this.category,
    this.imageUrl, required this.collected, required this.harvestCount,
    this.firstHarvestedAt,
  });

  // JSON 응답을 모델로 변환
  factory CollectionPlant.fromJson(Map<String, dynamic> json) => CollectionPlant(
    plantId: json['plantId'] ?? 0,
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    imageUrl: json['imageUrl'],
    collected: json['collected'] ?? false,
    harvestCount: json['harvestCount'] ?? 0,
    firstHarvestedAt: json['firstHarvestedAt'],
  );
}

// CollectionDetail — 도감 API 모델
class CollectionDetail {
  final int plantId;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;
  final bool collected;
  final int harvestCount;
  final List<HarvestedPlant> harvestedPlants;

  CollectionDetail({
    required this.plantId, required this.name, required this.category,
    this.description, this.imageUrl, required this.collected,
    required this.harvestCount, required this.harvestedPlants,
  });

  // JSON 응답을 모델로 변환
  factory CollectionDetail.fromJson(Map<String, dynamic> json) => CollectionDetail(
    plantId: json['plantId'] ?? 0,
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    description: json['description'],
    imageUrl: json['imageUrl'],
    collected: json['collected'] ?? false,
    harvestCount: json['harvestCount'] ?? 0,
    harvestedPlants: (json['harvestedPlants'] as List?)?.map((e) => HarvestedPlant.fromJson(e)).toList() ?? [],
  );
}

// HarvestedPlant — 도감 API 모델
class HarvestedPlant {
  final int userPlantId;
  final String nickname;
  final String? imageUrl;
  final String? plantedAt;
  final String? harvestedAt;

  HarvestedPlant({
    required this.userPlantId, required this.nickname, this.imageUrl,
    this.plantedAt, this.harvestedAt,
  });

  // JSON 응답을 모델로 변환
  factory HarvestedPlant.fromJson(Map<String, dynamic> json) => HarvestedPlant(
    userPlantId: json['userPlantId'] ?? 0,
    nickname: json['nickname'] ?? '',
    imageUrl: json['imageUrl'],
    plantedAt: json['plantedAt'],
    harvestedAt: json['harvestedAt'],
  );
}

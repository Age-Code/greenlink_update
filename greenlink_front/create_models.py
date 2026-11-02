import os

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

# auth_models.dart
auth_models = """class SignupRequest {
  final String email;
  final String password;
  final String nickname;
  SignupRequest({required this.email, required this.password, required this.nickname});
  Map<String, dynamic> toJson() => {'email': email, 'password': password, 'nickname': nickname};
}

class SignupResponse {
  final int userId;
  final String nickname;
  final List<GrantedItem> grantedItems;
  SignupResponse({required this.userId, required this.nickname, required this.grantedItems});
  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
    userId: json['userId'] ?? 0,
    nickname: json['nickname'] ?? '',
    grantedItems: (json['grantedItems'] as List?)?.map((i) => GrantedItem.fromJson(i)).toList() ?? [],
  );
}

class GrantedItem {
  final int userItemId;
  final String name;
  final String itemType;
  final String? imageUrl;
  GrantedItem({required this.userItemId, required this.name, required this.itemType, this.imageUrl});
  factory GrantedItem.fromJson(Map<String, dynamic> json) => GrantedItem(
    userItemId: json['userItemId'] ?? 0,
    name: json['name'] ?? '',
    itemType: json['itemType'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final LoginUser user;
  LoginResponse({required this.accessToken, required this.tokenType, required this.user});
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] ?? '',
    tokenType: json['tokenType'] ?? 'Bearer',
    user: LoginUser.fromJson(json['user']),
  );
}

class LoginUser {
  final int userId;
  final String email;
  final String nickname;
  LoginUser({required this.userId, required this.email, required this.nickname});
  factory LoginUser.fromJson(Map<String, dynamic> json) => LoginUser(
    userId: json['userId'] ?? 0,
    email: json['email'] ?? '',
    nickname: json['nickname'] ?? '',
  );
}
"""

# home_models.dart
home_models = """class HomeResponse {
  final HomeUser user;
  final HomeUserPlant? mainUserPlant;
  final Map<String, dynamic>? attendanceSummary;
  final Map<String, dynamic>? questSummary;

  HomeResponse({required this.user, this.mainUserPlant, this.attendanceSummary, this.questSummary});

  factory HomeResponse.fromJson(Map<String, dynamic> json) => HomeResponse(
    user: HomeUser.fromJson(json['user']),
    mainUserPlant: json['mainUserPlant'] != null ? HomeUserPlant.fromJson(json['mainUserPlant']) : null,
    attendanceSummary: json['attendanceSummary'],
    questSummary: json['questSummary'],
  );
}

class HomeUser {
  final int userId;
  final String nickname;
  HomeUser({required this.userId, required this.nickname});
  factory HomeUser.fromJson(Map<String, dynamic> json) => HomeUser(
    userId: json['userId'] ?? 0,
    nickname: json['nickname'] ?? '',
  );
}

class HomeUserPlant {
  final int userPlantId;
  final int plantId;
  final String plantName;
  final String nickname;
  final String status;
  final String? imageUrl;
  final int? daysAfterPlanting;
  final int? remainingDays;

  HomeUserPlant({
    required this.userPlantId, required this.plantId, required this.plantName,
    required this.nickname, required this.status, this.imageUrl,
    this.daysAfterPlanting, this.remainingDays,
  });

  factory HomeUserPlant.fromJson(Map<String, dynamic> json) => HomeUserPlant(
    userPlantId: json['userPlantId'] ?? 0,
    plantId: json['plantId'] ?? 0,
    plantName: json['plantName'] ?? '',
    nickname: json['nickname'] ?? '',
    status: json['status'] ?? '',
    imageUrl: json['imageUrl'],
    daysAfterPlanting: json['daysAfterPlanting'],
    remainingDays: json['remainingDays'],
  );
}
"""

# user_item_models.dart
user_item_models = """class UserItemGroup {
  final int itemId;
  final String name;
  final String itemType;
  final String? description;
  final String? imageUrl;
  final int ownedCount;
  final int usableCount;
  final int usedCount;
  final List<UserItemDetail> items;

  UserItemGroup({
    required this.itemId, required this.name, required this.itemType,
    this.description, this.imageUrl, required this.ownedCount,
    required this.usableCount, required this.usedCount, required this.items,
  });

  factory UserItemGroup.fromJson(Map<String, dynamic> json) {
    return UserItemGroup(
      itemId: json['itemId'] ?? 0,
      name: json['name'] ?? '',
      itemType: json['itemType'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      ownedCount: json['ownedCount'] ?? 0,
      usableCount: json['usableCount'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      items: (json['items'] as List?)?.map((i) => UserItemDetail.fromJson(i)).toList() ?? [],
    );
  }
}

class UserItemDetail {
  final int userItemId;
  final String status;
  final int? userPlantId;

  UserItemDetail({required this.userItemId, required this.status, this.userPlantId});

  factory UserItemDetail.fromJson(Map<String, dynamic> json) => UserItemDetail(
    userItemId: json['userItemId'] ?? 0,
    status: json['status'] ?? 'OWNED',
    userPlantId: json['userPlantId'],
  );
}
"""

# user_plant_models.dart
user_plant_models = """class UserPlantSummary {
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

class EquippedPot {
  final int userItemId;
  final int itemId;
  final String name;
  final String? imageUrl;

  EquippedPot({required this.userItemId, required this.itemId, required this.name, this.imageUrl});

  factory EquippedPot.fromJson(Map<String, dynamic> json) => EquippedPot(
    userItemId: json['userItemId'] ?? 0,
    itemId: json['itemId'] ?? 0,
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'],
  );
}
"""

# collection_models.dart
collection_models = """class CollectionPlant {
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

  factory HarvestedPlant.fromJson(Map<String, dynamic> json) => HarvestedPlant(
    userPlantId: json['userPlantId'] ?? 0,
    nickname: json['nickname'] ?? '',
    imageUrl: json['imageUrl'],
    plantedAt: json['plantedAt'],
    harvestedAt: json['harvestedAt'],
  );
}
"""

# quest_models.dart
quest_models = """class UserQuestSummary {
  final int userQuestId;
  final String questType;
  final String title;
  final String status;
  final int targetValue;
  final int progressValue;

  UserQuestSummary({
    required this.userQuestId, required this.questType, required this.title,
    required this.status, required this.targetValue, required this.progressValue,
  });

  factory UserQuestSummary.fromJson(Map<String, dynamic> json) => UserQuestSummary(
    userQuestId: json['userQuestId'] ?? 0,
    questType: json['questType'] ?? '',
    title: json['title'] ?? '',
    status: json['status'] ?? 'IN_PROGRESS',
    targetValue: json['targetValue'] ?? 0,
    progressValue: json['progressValue'] ?? 0,
  );
}

class UserQuestDetail {
  final int userQuestId;
  final String title;
  final String description;
  final String questType;
  final String targetType;
  final int targetValue;
  final int progressValue;
  final String status;
  final String? startedAt;
  final String? expiredAt;
  final RewardItem? rewardItem;

  UserQuestDetail({
    required this.userQuestId, required this.title, required this.description,
    required this.questType, required this.targetType, required this.targetValue,
    required this.progressValue, required this.status, this.startedAt,
    this.expiredAt, this.rewardItem,
  });

  factory UserQuestDetail.fromJson(Map<String, dynamic> json) => UserQuestDetail(
    userQuestId: json['userQuestId'] ?? 0,
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    questType: json['questType'] ?? '',
    targetType: json['targetType'] ?? '',
    targetValue: json['targetValue'] ?? 0,
    progressValue: json['progressValue'] ?? 0,
    status: json['status'] ?? 'IN_PROGRESS',
    startedAt: json['startedAt'],
    expiredAt: json['expiredAt'],
    rewardItem: json['rewardItem'] != null ? RewardItem.fromJson(json['rewardItem']) : null,
  );
}

class RewardItem {
  final int itemId;
  final String name;
  final String itemType;
  final int quantity;
  final String? imageUrl;

  RewardItem({
    required this.itemId, required this.name, required this.itemType,
    required this.quantity, this.imageUrl,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    itemId: json['itemId'] ?? 0,
    name: json['name'] ?? '',
    itemType: json['itemType'] ?? '',
    quantity: json['quantity'] ?? 1,
    imageUrl: json['imageUrl'],
  );
}

class QuestRewardResponse {
  final RewardResult reward;
  final List<CreatedUserItem> createdItems;

  QuestRewardResponse({required this.reward, required this.createdItems});

  factory QuestRewardResponse.fromJson(Map<String, dynamic> json) => QuestRewardResponse(
    reward: RewardResult.fromJson(json['reward']),
    createdItems: (json['createdItems'] as List?)?.map((i) => CreatedUserItem.fromJson(i)).toList() ?? [],
  );
}

class RewardResult {
  final String itemName;
  final String itemType;
  final int quantity;

  RewardResult({required this.itemName, required this.itemType, required this.quantity});

  factory RewardResult.fromJson(Map<String, dynamic> json) => RewardResult(
    itemName: json['itemName'] ?? '',
    itemType: json['itemType'] ?? '',
    quantity: json['quantity'] ?? 1,
  );
}

class CreatedUserItem {
  final int userItemId;
  CreatedUserItem({required this.userItemId});
  factory CreatedUserItem.fromJson(Map<String, dynamic> json) => CreatedUserItem(
    userItemId: json['userItemId'] ?? 0,
  );
}
"""

# attend_models.dart
attend_models = """class AttendMonth {
  final int year;
  final int month;
  final int attendanceCount;
  final int currentStreak;
  final List<AttendDay> days;

  AttendMonth({
    required this.year, required this.month, required this.attendanceCount,
    required this.currentStreak, required this.days,
  });

  factory AttendMonth.fromJson(Map<String, dynamic> json) => AttendMonth(
    year: json['year'] ?? 0,
    month: json['month'] ?? 0,
    attendanceCount: json['attendanceCount'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    days: (json['days'] as List?)?.map((e) => AttendDay.fromJson(e)).toList() ?? [],
  );
}

class AttendDay {
  final int day;
  final bool attended;
  final String? attendedAt;

  AttendDay({required this.day, required this.attended, this.attendedAt});

  factory AttendDay.fromJson(Map<String, dynamic> json) => AttendDay(
    day: json['day'] ?? 0,
    attended: json['attended'] ?? false,
    attendedAt: json['attendedAt'],
  );
}

class AttendTodayResponse {
  final bool isConsecutive;
  final int streakDays;

  AttendTodayResponse({required this.isConsecutive, required this.streakDays});

  factory AttendTodayResponse.fromJson(Map<String, dynamic> json) => AttendTodayResponse(
    isConsecutive: json['isConsecutive'] ?? false,
    streakDays: json['streakDays'] ?? 1,
  );
}
"""

def write_models():
    create_file('lib/models/auth_models.dart', auth_models)
    create_file('lib/models/home_models.dart', home_models)
    create_file('lib/models/user_item_models.dart', user_item_models)
    create_file('lib/models/user_plant_models.dart', user_plant_models)
    create_file('lib/models/collection_models.dart', collection_models)
    create_file('lib/models/quest_models.dart', quest_models)
    create_file('lib/models/attend_models.dart', attend_models)

write_models()
print("Models created.")

import os

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

files = {
    'models/user.dart': '''
class User {
  final int userId;
  final String email;
  final String nickname;
  final String role;
  final String? createdAt;

  User({required this.userId, required this.email, required this.nickname, required this.role, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? 0,
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      role: json['role'] ?? 'USER',
      createdAt: json['createdAt'],
    );
  }
}
''',
    'models/plant.dart': '''
class Plant {
  final int plantId;
  final String name;
  final String? category;
  final String? description;
  final String? imageUrl;
  final int? growthDays;

  Plant({
    required this.plantId,
    required this.name,
    this.category,
    this.description,
    this.imageUrl,
    this.growthDays,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      plantId: json['plantId'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      growthDays: json['growthDays'],
    );
  }
}

class UserPlant {
  final int userPlantId;
  final int plantId;
  final String plantName;
  final String nickname;
  final String status;
  final String? imageUrl;
  final String? plantedAt;
  final String? harvestedAt;
  final int? daysAfterPlanting;
  final int? remainingDays;
  final dynamic equippedPot;

  UserPlant({
    required this.userPlantId,
    required this.plantId,
    required this.plantName,
    required this.nickname,
    required this.status,
    this.imageUrl,
    this.plantedAt,
    this.harvestedAt,
    this.daysAfterPlanting,
    this.remainingDays,
    this.equippedPot,
  });

  factory UserPlant.fromJson(Map<String, dynamic> json) {
    return UserPlant(
      userPlantId: json['userPlantId'] ?? 0,
      plantId: json['plantId'] ?? 0,
      plantName: json['plantName'] ?? '',
      nickname: json['nickname'] ?? '',
      status: json['status'] ?? 'GROWING',
      imageUrl: json['imageUrl'],
      plantedAt: json['plantedAt'],
      harvestedAt: json['harvestedAt'],
      daysAfterPlanting: json['daysAfterPlanting'],
      remainingDays: json['remainingDays'],
      equippedPot: json['equippedPot'],
    );
  }
}

class CollectionPlant {
  final int plantId;
  final String name;
  final String? category;
  final String? description;
  final String? imageUrl;
  final bool collected;
  final int harvestCount;
  final String? firstHarvestedAt;
  final List<dynamic>? harvestedPlants;

  CollectionPlant({
    required this.plantId,
    required this.name,
    this.category,
    this.description,
    this.imageUrl,
    required this.collected,
    required this.harvestCount,
    this.firstHarvestedAt,
    this.harvestedPlants,
  });

  factory CollectionPlant.fromJson(Map<String, dynamic> json) {
    return CollectionPlant(
      plantId: json['plantId'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      collected: json['collected'] ?? false,
      harvestCount: json['harvestCount'] ?? 0,
      firstHarvestedAt: json['firstHarvestedAt'],
      harvestedPlants: json['harvestedPlants'],
    );
  }
}
''',
    'models/item.dart': '''
class Item {
  final int itemId;
  final String name;
  final String itemType;
  final String? description;
  final String? imageUrl;
  final int? linkedPlantId;
  
  Item({
    required this.itemId,
    required this.name,
    required this.itemType,
    this.description,
    this.imageUrl,
    this.linkedPlantId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] ?? 0,
      name: json['name'] ?? '',
      itemType: json['itemType'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      linkedPlantId: json['linkedPlantId'],
    );
  }
}

class UserItem {
  final int userItemId;
  final String status;
  final int? userPlantId;
  final String? createdAt;

  UserItem({
    required this.userItemId,
    required this.status,
    this.userPlantId,
    this.createdAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      userItemId: json['userItemId'] ?? 0,
      status: json['status'] ?? 'OWNED',
      userPlantId: json['userPlantId'],
      createdAt: json['createdAt'],
    );
  }
}

class InventoryItem extends Item {
  final int ownedCount;
  final int usableCount;
  final int usedCount;
  final List<UserItem> items;

  InventoryItem({
    required int itemId,
    required String name,
    required String itemType,
    String? description,
    String? imageUrl,
    int? linkedPlantId,
    required this.ownedCount,
    required this.usableCount,
    required this.usedCount,
    required this.items,
  }) : super(
          itemId: itemId,
          name: name,
          itemType: itemType,
          description: description,
          imageUrl: imageUrl,
          linkedPlantId: linkedPlantId,
        );

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<UserItem> itemsList = list.map((i) => UserItem.fromJson(i)).toList();

    return InventoryItem(
      itemId: json['itemId'] ?? 0,
      name: json['name'] ?? '',
      itemType: json['itemType'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      linkedPlantId: json['linkedPlantId'],
      ownedCount: json['ownedCount'] ?? 0,
      usableCount: json['usableCount'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      items: itemsList,
    );
  }
}
''',
    'models/quest.dart': '''
class Quest {
  final int questId;
  final String title;
  final String? description;
  final String questType;
  final String targetType;
  final int targetValue;
  final dynamic rewardItem;
  final int? rewardQuantity;
  final String? resetCycle;
  final bool? active;

  Quest({
    required this.questId,
    required this.title,
    this.description,
    required this.questType,
    required this.targetType,
    required this.targetValue,
    this.rewardItem,
    this.rewardQuantity,
    this.resetCycle,
    this.active,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      questId: json['questId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      questType: json['questType'] ?? '',
      targetType: json['targetType'] ?? '',
      targetValue: json['targetValue'] ?? 0,
      rewardItem: json['rewardItem'],
      rewardQuantity: json['rewardQuantity'],
      resetCycle: json['resetCycle'],
      active: json['active'],
    );
  }
}

class UserQuest {
  final int userQuestId;
  final int questId;
  final String title;
  final String? description;
  final String questType;
  final String targetType;
  final int targetValue;
  final int progressValue;
  final String status;
  final String? startedAt;
  final String? expiredAt;
  final dynamic rewardItem;
  final int? rewardQuantity;

  UserQuest({
    required this.userQuestId,
    required this.questId,
    required this.title,
    this.description,
    required this.questType,
    required this.targetType,
    required this.targetValue,
    required this.progressValue,
    required this.status,
    this.startedAt,
    this.expiredAt,
    this.rewardItem,
    this.rewardQuantity,
  });

  factory UserQuest.fromJson(Map<String, dynamic> json) {
    return UserQuest(
      userQuestId: json['userQuestId'] ?? 0,
      questId: json['questId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      questType: json['questType'] ?? '',
      targetType: json['targetType'] ?? '',
      targetValue: json['targetValue'] ?? 0,
      progressValue: json['progressValue'] ?? 0,
      status: json['status'] ?? 'IN_PROGRESS',
      startedAt: json['startedAt'],
      expiredAt: json['expiredAt'],
      rewardItem: json['rewardItem'],
      rewardQuantity: json['rewardQuantity'],
    );
  }
}
''',
    'models/attend.dart': '''
class Attend {
  final String attendDate;
  final int streakCount;

  Attend({required this.attendDate, required this.streakCount});

  factory Attend.fromJson(Map<String, dynamic> json) {
    return Attend(
      attendDate: json['attendDate'] ?? '',
      streakCount: json['streakCount'] ?? 0,
    );
  }
}

class AttendStatus {
  final int year;
  final int month;
  final int totalAttendCount;
  final int currentStreakCount;
  final List<Attend> attends;

  AttendStatus({
    required this.year,
    required this.month,
    required this.totalAttendCount,
    required this.currentStreakCount,
    required this.attends,
  });

  factory AttendStatus.fromJson(Map<String, dynamic> json) {
    var list = json['attends'] as List? ?? [];
    List<Attend> attendsList = list.map((i) => Attend.fromJson(i)).toList();

    return AttendStatus(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      totalAttendCount: json['totalAttendCount'] ?? 0,
      currentStreakCount: json['currentStreakCount'] ?? 0,
      attends: attendsList,
    );
  }
}
'''
}

for file_path, content in files.items():
    full_path = os.path.join(base_dir, file_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)

print("Files generated successfully.")

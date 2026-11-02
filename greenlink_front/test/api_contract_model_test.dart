import 'package:flutter_test/flutter_test.dart';
import 'package:front/models/attend_models.dart';
import 'package:front/models/auth_models.dart';
import 'package:front/models/automation_models.dart';
import 'package:front/models/quest_models.dart';

void main() {
  test('today attendance maps backend streakCount', () {
    final response = AttendTodayResponse.fromJson({
      'streakCount': 7,
    });

    expect(response.streakDays, 7);
    expect(response.isConsecutive, isTrue);
  });

  test('today attendance supports the legacy streakDays key', () {
    final response = AttendTodayResponse.fromJson({
      'streakDays': 1,
    });

    expect(response.streakDays, 1);
    expect(response.isConsecutive, isFalse);
  });

  test('quest detail maps root rewardQuantity', () {
    final detail = UserQuestDetail.fromJson({
      'userQuestId': 10,
      'rewardQuantity': 3,
      'rewardItem': {
        'itemId': 20,
        'name': '영양제',
        'itemType': 'NUTRIENT',
      },
    });

    expect(detail.rewardQuantity, 3);
    expect(detail.rewardItem?.itemId, 20);
  });

  test('quest reward maps backend createdUserItems', () {
    final response = QuestRewardResponse.fromJson({
      'reward': {
        'itemName': '영양제',
        'itemType': 'NUTRIENT',
        'quantity': 2,
      },
      'createdUserItems': [
        {'userItemId': 31},
        {'userItemId': 32},
      ],
    });

    expect(
      response.createdItems.map((item) => item.userItemId).toList(),
      [31, 32],
    );
  });

  test('signup granted item falls back to backend itemId', () {
    final item = GrantedItem.fromJson({
      'itemId': 41,
      'name': '기본 화분',
      'itemType': 'POT',
    });

    expect(item.userItemId, 41);
  });

  test('automation defaults match backend createDefault when fields missing', () {
    final setting = AutomationSettingModel.fromJson({'userPlantId': 5});

    expect(setting.autoWaterEnabled, isFalse);
    expect(setting.autoLightEnabled, isFalse);
    expect(setting.autoOptimizeEnabled, isFalse);
    expect(setting.wateringSafetyEnabled, isFalse);
    expect(setting.lightStartTime, '08:00:00');
    expect(setting.lightEndTime, '18:00:00');
  });

  test('automation settings keep backend values when provided', () {
    final setting = AutomationSettingModel.fromJson({
      'userPlantId': 5,
      'autoWaterEnabled': true,
      'wateringSafetyEnabled': true,
      'lightStartTime': '09:30:00',
    });

    expect(setting.autoWaterEnabled, isTrue);
    expect(setting.wateringSafetyEnabled, isTrue);
    expect(setting.lightStartTime, '09:30:00');
    expect(setting.autoLightEnabled, isFalse);
  });
}

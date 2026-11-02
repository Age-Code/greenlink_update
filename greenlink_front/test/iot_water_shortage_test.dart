import 'package:flutter_test/flutter_test.dart';
import 'package:front/models/iot_models.dart';

void main() {
  IotLatestStatus latestWithSoil(double? moisture) {
    return IotLatestStatus.fromJson({
      'userPlantId': 5,
      'soil': {
        'sensorDataId': 1,
        'soilMoistureRaw': 2500,
        'soilMoisturePercent': moisture,
        'measuredAt': '2026-05-20T18:10:00',
      },
    });
  }

  test('soilMoisturePercent 24.5 is water shortage', () {
    final latest = latestWithSoil(24.5);

    expect(latest.isWaterShortage, isTrue);
    expect(latest.soilMoisturePercent, 24.5);
  });

  test('soilMoisturePercent 30.0 is not water shortage', () {
    final latest = latestWithSoil(30.0);

    expect(latest.isWaterShortage, isFalse);
  });

  test('soilMoisturePercent 80.0 is not water shortage', () {
    final latest = latestWithSoil(80.0);

    expect(latest.isWaterShortage, isFalse);
  });

  test('null soil is not water shortage', () {
    final latest = IotLatestStatus.fromJson({
      'userPlantId': 5,
      'soil': null,
    });

    expect(latest.isWaterShortage, isFalse);
    expect(latest.soilMoisturePercent, isNull);
  });

  test('null soilMoisturePercent is not water shortage', () {
    final latest = latestWithSoil(null);

    expect(latest.isWaterShortage, isFalse);
    expect(latest.soilMoisturePercent, isNull);
  });

  test('soilMoisturePercent 82.3 is too wet and cannot water', () {
    final latest = latestWithSoil(82.3);

    expect(latest.isTooWet, isTrue);
    expect(latest.canWater, isFalse);
  });

  test('soilMoisturePercent 80.0 is too wet and cannot water', () {
    final latest = latestWithSoil(80.0);

    expect(latest.isTooWet, isTrue);
    expect(latest.canWater, isFalse);
  });

  test('soilMoisturePercent 79.9 can water', () {
    final latest = latestWithSoil(79.9);

    expect(latest.isTooWet, isFalse);
    expect(latest.canWater, isTrue);
  });

  IotLatestStatus latestWithWatering(
    double moisture,
    Map<String, dynamic> watering,
  ) {
    return IotLatestStatus.fromJson({
      'userPlantId': 5,
      'soil': {'soilMoisturePercent': moisture},
      'watering': watering,
    });
  }

  test('server block decision overrides the local too-wet constant', () {
    // 서버가 안전 모드 기준(35+10=45%)으로 차단한 상태 — 앱 상수 80%보다 낮다.
    final latest = latestWithWatering(50.0, {
      'canWater': false,
      'blockReason': '토양 수분이 50.0%로 충분하여 급수가 차단되었습니다.',
      'shortageThresholdPercent': 35.0,
    });

    expect(latest.canWater, isFalse);
    expect(latest.isTooWet, isTrue);
    expect(latest.waterBlockReason, contains('50.0%'));
  });

  test('server allow decision overrides the local too-wet constant', () {
    // 안전 모드가 꺼져 있으면 85%여도 앱이 임의로 막지 않는다.
    final latest = latestWithWatering(85.0, {
      'canWater': true,
      'shortageThresholdPercent': 35.0,
    });

    expect(latest.canWater, isTrue);
    expect(latest.isTooWet, isFalse);
    expect(latest.waterBlockReason, isNull);
  });

  test('server shortage threshold is used for the shortage banner', () {
    final latest = latestWithWatering(32.0, {
      'canWater': true,
      'shortageThresholdPercent': 35.0,
    });

    // 앱 상수(30%) 기준이면 부족이 아니지만 서버 기준(35%)에서는 부족이다.
    expect(latest.isWaterShortage, isTrue);
  });

  test('falls back to local constants when watering is absent', () {
    final latest = latestWithSoil(82.3);

    expect(latest.canWater, isFalse);
    expect(latest.waterBlockReason, isNull);
  });
}

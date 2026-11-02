import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/core/utils/relative_time.dart';
import 'package:front/models/iot_models.dart';
import 'package:front/screens/iot/widgets/device_activity_card.dart';

void main() {
  test('latest status parses light state and recent commands', () {
    final status = IotLatestStatus.fromJson({
      'userPlantId': 5,
      'light': {'on': true, 'changedAt': '2026-11-02T09:00:00'},
      'recentCommands': [
        {'commandId': 1, 'commandType': 'WATER', 'commandStatus': 'PENDING'},
        {'commandId': 2, 'commandType': 'LIGHT_ON', 'commandStatus': 'SUCCESS'},
      ],
      'environment': {
        'temperature': 22,
        'humidity': 50,
        'light': 300,
        'measuredAt': '2026-11-02T08:00:00',
      },
      'soil': {'soilMoisturePercent': 40, 'measuredAt': '2026-11-02T08:30:00'},
    });

    expect(status.light?.on, isTrue);
    expect(status.recentCommands, hasLength(2));
    expect(status.recentCommands.first.isInProgress, isTrue);
    expect(status.lastMeasuredAt, DateTime.parse('2026-11-02T08:30:00'));
  });

  test('latest status tolerates missing new fields from older servers', () {
    final status = IotLatestStatus.fromJson({'userPlantId': 5});

    expect(status.light, isNull);
    expect(status.recentCommands, isEmpty);
    expect(status.lastMeasuredAt, isNull);
  });

  test('sensor history splits environment series and skips invalid points', () {
    final history = SensorHistory.fromJson({
      'hours': 24,
      'soil': [
        {'measuredAt': '2026-11-02T08:00:00', 'soilMoisturePercent': 40.5},
        {'measuredAt': null, 'soilMoisturePercent': 41},
      ],
      'environment': [
        {'measuredAt': '2026-11-02T08:00:00', 'temperature': 22, 'humidity': 51, 'light': 120},
      ],
    });

    expect(history.soilMoisture.single.value, 40.5);
    expect(history.temperature.single.value, 22);
    expect(history.humidity.single.value, 51);
    expect(history.light.single.value, 120);
  });

  test('relative time uses minutes, hours and days', () {
    final now = DateTime(2026, 11, 2, 12);

    expect(formatRelativeTime(now, now: now), '방금 전');
    expect(formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now), '5분 전');
    expect(formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now), '3시간 전');
    expect(formatRelativeTime(now.subtract(const Duration(days: 2)), now: now), '2일 전');
  });

  testWidgets('device activity card shows light state and failed reason', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceActivityCard(
            light: LightState(on: false),
            commands: [
              CommandSummary(
                commandType: 'WATER',
                commandStatus: 'FAILED',
                resultMessage: '펌프 GPIO 불일치',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('조명 꺼짐'), findsOneWidget);
    expect(find.text('물 주기 · 실패'), findsOneWidget);
    expect(find.text('펌프 GPIO 불일치'), findsOneWidget);
  });
}

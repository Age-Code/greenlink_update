import 'package:flutter_test/flutter_test.dart';
import 'package:front/services/automation_service.dart';

void main() {
  test('toServerTimeValue normalizes H:mm, HH:mm and HH:mm:ss', () {
    expect(toServerTimeValue('9:30'), '09:30:00');
    expect(toServerTimeValue('09:30'), '09:30:00');
    expect(toServerTimeValue('18:05:07'), '18:05:07');
  });

  test('toServerTimeValue falls back for empty or invalid input', () {
    expect(toServerTimeValue(null), '08:00:00');
    expect(toServerTimeValue(''), '08:00:00');
    expect(toServerTimeValue('25:00', defaultValue: '18:00:00'), '18:00:00');
    expect(toServerTimeValue('ab:cd'), '08:00:00');
  });
}

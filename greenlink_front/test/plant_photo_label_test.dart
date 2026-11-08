import 'package:flutter_test/flutter_test.dart';
import 'package:front/screens/home/home_page.dart';

void main() {
  test('plant photo label shows capture date or default image', () {
    expect(plantPhotoLabel('2026-11-08T17:40:12'), '11월 8일 촬영');
    expect(plantPhotoLabel(null), '기본 이미지');
    expect(plantPhotoLabel('not-a-date'), '기본 이미지');
  });
}

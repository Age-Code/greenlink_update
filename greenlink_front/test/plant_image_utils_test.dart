import 'package:flutter_test/flutter_test.dart';
import 'package:front/core/utils/plant_image_utils.dart';

void main() {
  const origin = 'https://greenlink.likepigs.shop';

  test('server-relative captured photo path gets the server origin', () {
    expect(
      resolveImageUrl('/images/userplant/a.jpg', serverOrigin: origin),
      'https://greenlink.likepigs.shop/images/userplant/a.jpg',
    );
  });

  test('absolute URLs are kept and invalid values are dropped', () {
    expect(resolveImageUrl('https://cdn.example.com/a.png', serverOrigin: origin),
        'https://cdn.example.com/a.png');
    expect(resolveImageUrl('', serverOrigin: origin), isNull);
    expect(resolveImageUrl(null, serverOrigin: origin), isNull);
    expect(resolveImageUrl('relative/no-slash.jpg', serverOrigin: origin), isNull);
  });

  test('thumbnail prefers captured photo and falls back to plant image', () {
    expect(
      getPlantThumbnailUrl(capturedImageUrl: null, fallbackImageUrl: 'https://x/plant.png'),
      'https://x/plant.png',
    );
    expect(getPlantThumbnailUrl(capturedImageUrl: null), isNull);
  });
}

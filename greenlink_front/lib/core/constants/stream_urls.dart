// 카메라 스트림 URL 상수

// 카메라 스트림 URL 상수
class StreamUrls {
  // 환경별 전환은 빌드 시 --dart-define=GREENLINK_STREAM_BASE_URL=... 로 주입한다.
  // 지정하지 않으면 기존 운영 주소를 그대로 사용한다.
  static const String baseUrl = String.fromEnvironment(
    'GREENLINK_STREAM_BASE_URL',
    defaultValue: 'https://camera.likepigs.shop',
  );

  static const String all = '$baseUrl/stream.mjpg';
  static const String sunflower = '$baseUrl/stream/sunflower.mjpg';
  static const String basil = '$baseUrl/stream/basil.mjpg';
}

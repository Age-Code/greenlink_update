// 카메라 스트림 URL 설정

import '../constants/stream_urls.dart';

// 카메라 설정 — 재배기 한 대에 식물 한 개 기준이므로 전체 화면 스트림 하나를 사용
class CameraConfig {
  CameraConfig._();

  // 라즈베리파이 실시간 MJPEG 스트림 주소
  static const String streamUrl = StreamUrls.all;

  // 식물 카메라 스트림 URL 반환 — 식물이 하나이므로 userPlantId와 무관하게 전체 화면
  static String getCameraStreamUrl(int userPlantId) {
    return streamUrl;
  }
}

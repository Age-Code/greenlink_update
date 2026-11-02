// 식물별 스트림 URL 매핑

import '../constants/stream_urls.dart';

// 카메라 설정 — 식물별 스트림 URL 반환
class CameraConfig {
  CameraConfig._();

  // 라즈베리파이 실시간 MJPEG 스트림 주소
  static const String streamUrl = StreamUrls.all;

  // 식물별 카메라 스트림 URL 반환 — 등록 식물 ID 기준 분기
  static String getCameraStreamUrl(int userPlantId) {
    if (userPlantId == 5) {
      return StreamUrls.sunflower;
    }

    if (userPlantId == 6) {
      return StreamUrls.basil;
    }

    return streamUrl;
  }
}

// IoT 토양수분 부족/과습 판정 상수 — 서버가 기준을 내려주지 않을 때만 쓰는 fallback

// IoT 판정 기준 상수 — 서버 응답의 watering 값이 없을 때만 사용한다.
class IotThresholds {
  static const double soilMoistureShortage = 30.0;
  static const double soilMoistureTooWet = 80.0;
}

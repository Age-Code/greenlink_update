# GreenLink Frontend

GreenLink의 Flutter 사용자 앱입니다. 인증, 식물 육성, 인벤토리, 출석/퀘스트,
컬렉션, IoT 센서 조회·제어, Raspberry Pi MJPEG 스트림 표시 기능을 제공합니다.

## 주요 구조

```text
lib/
├── core/       # API 경로, 네트워크, 토큰 저장, 공통 유틸리티
├── models/     # 백엔드 응답 모델
├── services/   # 기능별 REST API 호출
├── screens/    # 인증, 홈, 식물, 인벤토리, 퀘스트, IoT 화면
├── widgets/    # 공통 및 기능 위젯
└── main.dart   # 앱 초기화와 전역 Navigator
test/           # IoT 임계치 및 API 응답 계약 테스트
```

## 실행

Flutter SDK와 호환되는 Dart SDK가 필요합니다. 프로젝트의 Dart SDK 범위는
`pubspec.yaml`을 기준으로 합니다.

```bash
flutter pub get
flutter run
```

## 검증

```bash
flutter analyze
flutter test
```

저장소에는 IoT 수분 판정 테스트 8개와 API 응답 계약 테스트 5개가 있습니다.
2026-07-24 문서 갱신 환경에는 Flutter/Dart SDK가 없어 총 13개 테스트와 정적
분석을 실행하지 못했습니다.

## 환경 설정 주의사항

백엔드 API 주소, MJPEG 스트림 주소, Kakao/Google OAuth 설정은 현재 Dart
소스에 직접 구성되어 있습니다. 환경을 바꾸거나 배포하기 전에 다음 파일의
설정을 확인해야 합니다.

- `lib/core/network/api_client.dart`
- `lib/core/constants/stream_urls.dart`
- `lib/core/config/camera_config.dart`
- `lib/main.dart`와 인증 화면

인증 토큰은 현재 `SharedPreferences`에 저장됩니다. Android 앱은 main
manifest에 인터넷 권한을 선언합니다. 실제 운영 배포 전에는 endpoint와
SDK/OAuth 설정의 환경별 주입, 토큰 저장 정책, MJPEG 접근 통제를 별도로
검토해야 합니다.

상세 구조와 현재 구현 분석은 `../docs/FRONTEND.md`를 참고하세요.

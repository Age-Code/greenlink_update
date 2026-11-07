<div align="center">

# 🌱 GreenLink

### 앱 속 반려식물과 현실 식물을 연결하는 IoT 기반 식물 성장 서비스

**V2R (Virtual-to-Reality) Plant Growth Platform**

*One tap, visible change, real harvest.*

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-4.0.6-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-A22846?logo=raspberrypi&logoColor=white)](https://www.raspberrypi.com/)
[![ESP32](https://img.shields.io/badge/ESP32-000000?logo=espressif&logoColor=white)](https://www.espressif.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare_Tunnel-F38020?logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)

</div>

---

## 📌 프로젝트 소개

**GreenLink**는 사용자가 앱에서 키우는 가상 반려식물을 실제 스마트팜의 식물과 연결하여, 앱 활동이 곧 실제 식물 관리로 이어지는 V2R(Virtual-to-Reality) 식물 성장 서비스입니다.

기존 식물 관리 앱은 시간 기반 알림에 그치지만, GreenLink는 앱에서의 행동(물주기·조명 제어)이 IoT 장치를 통해 실제 식물에 반영되고, 센서·카메라가 그 결과를 다시 앱으로 전달하는 **폐루프(Closed Loop) 경험**을 제공합니다.

> 2026년 봄학기 캡스톤 디자인 2 프로젝트
> 참여기업체: **필로** | 지도교수: **김세진 교수님**

---

## 🎯 해결하고자 한 문제

설문 조사 결과 식물 재배를 지속하지 못하는 주요 이유는 다음과 같았습니다.

| 비율 | 이유 |
|---|---|
| **63.3%** | 관리가 힘들어서 |
| **56.3%** | 식물이 시들어서 |
| **22.6%** | 벌레나 해충 때문 |

기존 솔루션은 다음 한계가 있습니다.

- 📱 **식물 관리 앱** (Greg, Planta, PictureThis): 단순 알림 위주, 실제 식물 상태 미반영
- 🪴 **스마트 식물재배기** (Click & Grow, LG 틔운): 정해진 식물·재배 방식 고정
- 🌾 **원격 스마트팜** (Infarm, 자람): B2B 중심, 개인 사용자 접근 어려움

GreenLink는 **앱 활동 기반 참여 + IoT 기반 실제 관리 + 센서·사진 기반 피드백**을 결합한 **V2R 반려식물 성장 서비스**를 지향합니다.

---

## ✨ 주요 기능

### 🌿 앱 / 식물 관리
- 회원가입·로그인 (이메일, Kakao·Google OAuth)
- 씨앗 사용을 통한 내 식물 생성, 별명 설정, 수확
- 식물 성장 상태 조회 (날짜 기준 GROWING / HARVESTABLE / HARVESTED)
- 인벤토리: 씨앗, 화분, 영양제 보유 및 사용 (영양제 1개당 수확까지 1일 단축)
- 화분 장착 (식물당 1개, 자동 교체)
- 수확 도감 (전체 식물 종 대비 수확 이력)

### 🎮 참여 유도 (게임화)
- 출석 체크 및 연속 출석(streak) 기록
- 일간 / 주간 / 월간 / 업적 퀘스트
- 퀘스트 진행도 자동 추적 (출석·수확 등 이벤트 연동)
- 보상 아이템 자동 지급

### 🌡️ IoT 센서 / 모니터링
- **ESP32 토양수분 센서**: 식물별 토양 수분 % 측정 및 자동 업로드
- **Raspberry Pi 환경 센서**: 온도·습도(DHT22), 조도(BH1750) 측정
- **실시간 MJPEG 영상 스트림**: 재배기 전체 화면 영상 제공
- **센서 기록 그래프**: 토양 수분·온도·습도·조도의 24시간/7일 추이
- **장치 상태 표시**: 조명 켜짐/꺼짐, 최근 명령 실행 결과(완료/실패 사유), 센서 장기 미수신 경고

### 💧 원격 제어 / 자동화
- 앱에서 수동 물주기·조명 제어 명령 전송
- Raspberry Pi 릴레이를 통한 LED·펌프 실제 제어
- 센서값 기반 자동 물주기·조명 판단 (AutomationService)
- 데이터 기반 자동화 임계치 학습 (AutomationLearningService)

### 📸 일일 식물 사진 (썸네일)
- Raspberry Pi가 매일 09:00 실시간 영상에서 한 장을 캡처해 업로드
- 백엔드가 서버 디스크(Docker 볼륨)에 저장하고 `/images/**`로 제공
- 앱 홈·식물 상세 화면의 썸네일로 표시 (촬영 날짜 함께 표시)
- 보관 기간(기본 30일)이 지난 사진은 자동 정리, 식물별 최신 사진은 유지

### 🛠️ 관리자
- Thymeleaf 기반 운영 대시보드: 사용자·식물 수, 장치 온라인/오프라인, 최근 명령과 24시간 실패 건수
- 사용자·식물·아이템·퀘스트·IoT 장치 관리

---

## 🏗️ 시스템 아키텍처

```mermaid
flowchart TD
    U[👤 사용자] -->|화면 조작| F[📱 Flutter 앱]
    F -->|JWT REST API| B[🟢 Spring Boot 백엔드]
    B --> DB[(🗄️ MySQL DB)]
    F -->|MJPEG 스트림| PS[📹 Pi 카메라 서버]
    ESP[🔌 ESP32<br/>토양수분 센서] -->|HTTP POST| B
    PI[🍓 Raspberry Pi<br/>환경센서·카메라·릴레이] -->|센서/사진 POST<br/>명령 polling| B
    B -->|제어 명령| PI
    B -->|매일 캡처 사진 저장| IMG[(🖼️ 서버 디스크<br/>/images)]
    F -->|썸네일 조회| IMG
```

### 데이터 흐름

| 흐름 | 경로 |
|---|---|
| **제어 요청** | Flutter → Spring Boot → Raspberry Pi → Relay → Pump/LED |
| **센서 데이터** | ESP32/RPi Sensors → Spring Boot → MySQL → Flutter |
| **식물 사진** | RPi Camera(매일 09:00) → Spring Boot → 서버 디스크 → Flutter 썸네일 |

---

## 🛠️ 기술 스택

<table>
<tr>
<td valign="top" width="50%">

### Frontend
- **Flutter** (Dart `^3.9.2`)
- Material UI
- `http`, `shared_preferences`
- Kakao Flutter SDK
- Google Sign-In

### Backend
- **Spring Boot 4.0.6** (Java 17)
- Spring Security + JWT(jjwt)
- Spring Data JPA
- Thymeleaf (관리자 화면)
- OAuth2 (Kakao / Google)

### Database
- **MySQL**
- Soft delete 기반 관리
- ddl-auto: update

</td>
<td valign="top" width="50%">

### IoT Devices
- **ESP32** + PlatformIO Arduino
  - 토양수분 ADC (GPIO 34)
- **Raspberry Pi**
  - DHT22 (GPIO 4), BH1750 (I2C 0x23)
  - 릴레이 (펌프 GPIO 22 기본·LED GPIO 27)
  - Pi Camera (MJPEG)
- Active-LOW 릴레이 회로

### Infrastructure
- 학교 서버(Windows WSL) **Docker Compose**
- **Cloudflare Tunnel** (HTTPS, `greenlink.likepigs.shop`)
- 사진 저장: 서버 디스크(Docker 볼륨)

</td>
</tr>
</table>

---

## 📂 프로젝트 구조

본 저장소는 **4개 모듈을 단일 모노레포(monorepo)** 로 관리합니다. 각 모듈은 독립적으로 빌드·실행 가능합니다.

```text
greenlink/
├── greenlink_back/      # Spring Boot 백엔드 (REST API, 인증, JPA, 관리자 웹)
├── greenlink_front/     # Flutter 앱 (사용자용 모바일 UI)
├── greenlink_esp/       # ESP32 펌웨어 (토양수분 센서)
├── greenlink_pi/        # Raspberry Pi (환경센서, 카메라, 릴레이 제어)
├── scripts/             # 운영 스크립트 (IoT 초기 구성)
└── docs/                # 기준 문서, 시스템 다이어그램, 판넬 자료
```

각 모듈별 상세 구조와 파일 역할은 `docs/` 폴더 내 다음 문서를 참고하세요.

- `PROJECT_OVERVIEW.md` — 전체 시스템 개요
- `BACKEND.md` — Spring Boot 백엔드
- `FRONTEND.md` — Flutter 앱
- `ESP.md` — ESP32 펌웨어
- `PI.md` — Raspberry Pi
- `DEPLOYMENT.md` — 학교 서버(winserver WSL Docker + Cloudflare 터널) 백엔드 배포 절차
- `INFRASTRUCTURE_SETUP_GUIDE.md` — (참고용, AWS 기준 구 가이드) 서버·DB·DNS·TLS·OAuth·IoT 구축 절차
- `HARDWARE_WIRING.md` — 실제 하드웨어 배선(핀 번호)과 단계별 연결·점검 절차
- `API_SPECIFICATION.md` — REST API 명세
- `FUNCTIONAL_SPECIFICATION.md` — 기능 명세

---

## ✅ 현재 코드 검증 기준

2026-11-02 기준으로 다음을 확인했습니다.

- Backend: H2 테스트 프로필 테스트 통과, Docker 이미지 빌드·기동, 운영 서버(`greenlink.likepigs.shop`) 외부 접속 확인
- Flutter: `flutter analyze` 에러 0, 테스트 통과
- Raspberry Pi: 급수 시간 검증·릴레이·명령 워커 unit test 통과 (GPIO 실물 시험은 별도)
- ESP32: PlatformIO 빌드 성공 (실기기 시험은 별도)

현재 Backend와 Pi는 WATER 명령을 모두 **0초 초과, 1초 이하**로 제한하는 fail-closed 정책을 적용합니다. `durationSeconds` key가 아예 없을 때만 Pi가 1초를 사용하며, null·문자열·boolean·비유한 수·0 이하·1초 초과 값은 펌프를 켜기 전에 거부하고 명령을 `FAILED`로 보고합니다. 1초는 물리적으로 검증된 최종값이 아니라 실측 전 보수적인 소프트웨어 상한이므로, 펌프 유량과 화분별 안전 급수량을 측정하기 전에는 늘리지 않는 것이 좋습니다. 자세한 산정 방법은 [Raspberry Pi 문서](./docs/PI.md)를 참고하세요.

## 🚀 실행 방법

> 실행 전, 각 모듈에서 필요한 값(JWT secret, DB 접속, OAuth 키, 장치 키 등)을 **외부 설정**으로 주입해야 합니다. 현재 소스와 설정에는 운영 URL·키·자격 정보 계열 값이 일부 포함되어 있으므로, 배포 전 외부화하고 노출 가능성이 있는 값은 교체해야 합니다. 문서에는 실제 값을 기록하지 않습니다.

### 1. Backend (Spring Boot)

```bash
cd greenlink_back
./gradlew bootRun       # 개발 서버 실행
./gradlew test          # 테스트
./gradlew build         # JAR 빌드
```

**필요 설정**: MySQL 접속 정보, JWT secret, OAuth 클라이언트 설정, 사진 저장 폴더(`GREENLINK_IMAGE_DIR`, 기본 `./data/images`). 운영 배포는 [DEPLOYMENT.md](./docs/DEPLOYMENT.md) 참고

**최초 기동**: 빈 DB면 기본 식물(바질)과 가입 지급 아이템(바질 씨앗, 기본 화분)이 자동 생성됩니다. ADMIN이 한 명도 없을 때 `GREENLINK_BOOTSTRAP_ADMIN_EMAIL`·`GREENLINK_BOOTSTRAP_ADMIN_PASSWORD`(12자 이상)를 주면 최초 관리자가 생성되며, 생성 후에는 두 환경변수를 제거합니다.

마지막 운영 확인 기록은 JAR를 수동 전송한 뒤 `screen` 세션에서 `java -jar`로 실행하는 방식입니다. Backend systemd unit과 자동 복구는 확인되지 않았습니다.

### 2. Frontend (Flutter)

```bash
cd greenlink_front
flutter pub get
flutter run             # 디바이스/에뮬레이터 실행
flutter build apk       # Android 빌드
flutter build ios       # iOS 빌드
```

**필요 설정**: API base URL, 카메라 스트림 URL, Kakao/Google OAuth 설정

### 3. ESP32 (PlatformIO)

```bash
cd greenlink_esp
pio run                 # 빌드
pio run -t upload       # 보드에 업로드
pio device monitor      # 시리얼 모니터
```

**필요 설정**: Wi-Fi SSID/비밀번호, 서버 endpoint, 장치 키

### 4. Raspberry Pi

```bash
cd greenlink_pi
python3 -m venv .venv
source .venv/bin/activate
# 필요 패키지 설치 (RPi.GPIO, picamera2, adafruit_dht 등)

# 센서 측정 및 업로드
python3 sensor_main.py

# 카메라 MJPEG 스트림 서버
python3 stream_server.py

# 명령 폴링 및 펌프/LED 제어 워커
python3 command_worker.py
```

**필요 설정**: 서버 endpoint, 장치 키, 펌프 GPIO(`GREENLINK_PUMP_GPIO`, 기본 22). 재배기 1대에 식물 1개를 기준으로 하며 카메라는 전체 화면을 사용합니다. 식물 ID(`GREENLINK_USER_PLANT_ID`)는 선택이며, 비워 두면 Backend가 재배기에 연결된 현재 식물에 사진을 붙입니다. 상시 실행 서비스는 `greenlink_pi/systemd/`, 주기 작업은 `crontab.example`을 사용합니다. (`greenlink.env.example` 참고)

**배선**: 센서·릴레이·펌프·LED를 몇 번 핀에 꽂는지는 [하드웨어 연결 가이드](./docs/HARDWARE_WIRING.md)를 따릅니다.

---

## 📊 구현 현황

| 구분 | 상태 | 비고 |
|---|---|---|
| 회원가입 / 로그인 (일반·OAuth) | ✅ 구현 완료 | Kakao·Google 포함 |
| 식물 등록 / 성장 / 수확 | ✅ 구현 완료 | 날짜 기준 상태 전환 |
| 인벤토리 / 화분 장착 / 영양제 | ✅ 구현 완료 | |
| 출석 / 퀘스트 / 도감 | ✅ 구현 완료 | ATTEND·HARVEST 자동 연동 |
| ESP32 토양수분 측정 | ✅ 구현 완료 | 10분 주기 |
| Pi 환경 센서 / 카메라 스트림 | ✅ 구현 완료 | DHT22, BH1750, MJPEG |
| 수동 / 자동 물주기 · 조명 | ⚠️ 부분 구현 | DeviceCommand 기반, Backend/Pi 양쪽 WATER 1초 상한 적용. 물리 유량 보정 필요 |
| 일일 식물 사진 썸네일 | ✅ 구현 완료 | 매일 09:00 캡처, 서버 디스크 저장, 30일 보관 |
| Admin Dashboard | ✅ 구현 완료 | 운영 현황 대시보드, HttpOnly cookie 로그인 |
| 서버 배포 | ✅ 운영 중 | 학교 서버 Docker + Cloudflare Tunnel (`greenlink.likepigs.shop`) |

---

## 🏆 차별점

| 기능 영역 | 식물 관리 앱 | 스마트 재배기 | 원격 스마트팜 | **GreenLink** |
|---|:---:|:---:|:---:|:---:|
| 식물 등록 / 도감 | ◯ | ◯ | △ | **◯** |
| 실제 재배기 연동 | ✕ | ◯ | ◯ | **◯** |
| 센서 데이터 확인 | ✕ | △ | △ | **◯** |
| 앱에서 원격 제어 | ✕ | △ | △ | **◯** |
| 앱 활동 ↔ 실제 연동 | ✕ | △ | ✕ | **◯** |
| 퀘스트 / 아이템 게임화 | △ | ✕ | ✕ | **◯** |
| 반려식물 성장 경험 | ◯ | △ | ✕ | **◯** |

---

## 👥 팀

| 이름 | GitHub |
|---|---|
| **안광은** | [@Age-Code](https://github.com/Age-Code) |
| **김민제** | [@MinJe21](https://github.com/MinJe21) |

**지도교수**: 김세진 교수님
**참여기업체**: 필로

---

## 📄 문서

자세한 기술 문서는 `docs/` 폴더를 참고하세요.

- 📐 [시스템 개요](./docs/PROJECT_OVERVIEW.md)
- 🟢 [백엔드 분석](./docs/BACKEND.md)
- 📱 [프론트엔드 분석](./docs/FRONTEND.md)
- 🔌 [ESP32 펌웨어](./docs/ESP.md)
- 🍓 [Raspberry Pi](./docs/PI.md)
- 🚀 [배포 가이드](./docs/DEPLOYMENT.md)
- 🔧 [하드웨어 연결 가이드](./docs/HARDWARE_WIRING.md)
- 🏗️ [신규 인프라 구축·운영 가이드](./docs/INFRASTRUCTURE_SETUP_GUIDE.md)
- 🔗 [API 명세](./docs/API_SPECIFICATION.md)
- 📋 [기능 명세](./docs/FUNCTIONAL_SPECIFICATION.md)

---

<div align="center">

**🌱 GreenLink — 앱 활동이 실제 식물 관리로 이어지는 V2R 반려식물 성장 서비스**

2026 봄학기 캡스톤 디자인 2

</div>

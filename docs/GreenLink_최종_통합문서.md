# GreenLink 프로젝트 최신 통합 문서 (정합성 검증·최신화 최종본)

> **2026-11 변경**: AI 이미지 변환(OpenAI + rembg, Ubuntu AI Worker, `/api/ai/**`, `AiPlantImage`)과 AWS S3 저장은 제거되었습니다. 현재는 Raspberry Pi가 매일 09:00 실시간 영상에서 한 장을 캡처해 업로드하고, 백엔드가 서버 디스크(Docker 볼륨)에 저장해 `/images/**`로 제공하며 앱 썸네일로 씁니다. 재배기 1대 = 식물 1개 구성입니다. 아래 본문의 AI/S3 관련 내용은 이전 구성 기록입니다.

> **작성 기준일**: 2026-07-24
>
> **이번 작업 원칙**: "추측 금지, 현재 코드 기준 문서 우선, 미구현 기능은 미구현으로 표시"
>
> **codex.zip 미첨부.** 본 문서는 다음을 현재 기준 근거로 사용합니다.
>
> 1. **8개 기준 markdown** (최우선): `API_SPECIFICATION.md`, `BACKEND.md`, `ESP.md`, `FRONTEND.md`, `FUNCTIONAL_SPECIFICATION.md`, `PI.md`, `PROJECT_OVERVIEW.md`, `UBUNTU_GREENLINK_AI.md`
> 2. **GAP_DECISION_REVIEW.md** (코드 직접 확인 + 사용자 운영 확인 결과) — 8개 문서의 "확인 필요" 다수를 확정/정정
> 3. **소스코드 확정값** (`openai_transform.py`, `remove_pot.py`, `DeviceCommand.java`, `AutomationSetting.java`, `AutomationModel.java`)
> 4. **최종 판넬 자료** (`1분반_안광은_김민제_GREENLINK김세진_판넬게시용.jpg`)
> 5. 과거 작업 기록 markdown 다수 (검증·수정 대상)
>
> 운영값(실서버 도메인/IP/포트 host/장치 키/JWT secret/OAuth·Kakao 키/버킷명/DB 계정)은 문서에 노출하지 않습니다.
>
> **본 최종본은 이전 Part 1~5를 하나로 통합하면서, Part 4·5의 정정·확정 사항과 2026-07-24 소스 재검증 결과를 본문에 반영**했습니다. 운영 환경 사실은 마지막 사용자 제공 확인 기록을 기준으로 하며, 이번 작업에서 서버에 다시 접속해 확인한 것은 아닙니다.

---

## 2026-07-24 최신 코드 보정

| 영역 | 이번 반영 | 검증 상태 |
| --- | --- | --- |
| Backend | LOCAL 계정만 비밀번호 로그인, OAuth 내부 비밀번호 무작위화, 월간 퀘스트 만료 계산, 현재 연속 출석 계산, 식물 상태 갱신 후 필터, Home/Auth 응답 계약 보정 | 테스트 17개 통과, `bootJar` 성공 |
| Flutter | 전역 401 로그인 이동·중복 방지, Android 인터넷 권한, 출석·퀘스트·가입 지급·Home 계약, D-day, 변경 요청 body 로그 보정 | 테스트 13개가 저장소에 있음. 현재 환경에 Flutter/Dart SDK가 없어 미실행 |
| Ubuntu AI | 작업명 이중 검증 + configured S3 virtual-host URL/prefix만 boto3 `get_object`로 읽고 URL·MIME·확장자·20MiB 선언/실제 stream 크기를 fail-close 검증 | 테스트 13개 통과. 실제 bucket 부재로 live `s3:GetObject`는 미검증 |
| Pi/WATER | Backend와 Pi가 모두 WATER를 `0 < durationSeconds <= 1`로 제한. Pi는 key가 없을 때만 1초 fallback | 테스트 5개 통과. GPIO 하드웨어·유량 시험은 미수행 |

현재 코드에서 별도로 남은 중요 결정은 다음 두 가지다.

- AI Worker의 직접 S3 읽기는 구현됐지만 실제 `s3:GetObject` 권한은 대상으로 삼을 bucket이 없어 live 확인하지 못했다. bucket 재생성 후 Worker 서비스와 같은 credential chain, `S3_BUCKET`/`AWS_REGION`, 알려진 기존 object로 확인해야 한다. bucket을 private로 운영한다면 Flutter가 naked `imageUrl`/`aiImageUrl`을 읽는 방식도 공개 object·presigned URL·Backend proxy·CDN 중 하나로 별도 결정해야 한다.
- 펌프의 소프트웨어 상한은 Backend와 Pi 모두 **1초 fail-close**로 구현됐다. 이 값은 유량·호스 높이·화분 안전 급수량 실측 전의 보수적 제한이지 물리적 안전을 보증하는 교정값은 아니다. 실제 유량 교정과 중복 worker/반복 명령·relay 고착 같은 운영 위험 검증은 별도로 남아 있다.

---

## 목차

- [0. 현재 기준 8개 markdown 파일 역할 및 전체 구조](#0-현재-기준-8개-markdown-파일-역할-및-전체-구조)
- [A. 프로젝트 최신 통합 문서](#a-프로젝트-최신-통합-문서)
- [B. 현재 기준 문서-과거 문서 정합성 검증 보고서](#b-현재-기준-문서-과거-문서-정합성-검증-보고서)
- [C. 기능별 최신 구현 현황](#c-기능별-최신-구현-현황)
- [D. API 최신 문서](#d-api-최신-문서)
- [E. DB 최신 문서](#e-db-최신-문서)
- [F. 현재 기준 파일별 설명 문서](#f-현재-기준-파일별-설명-문서)
- [G. 설정값 최신 기준](#g-설정값-최신-기준)
- [H. 오류와 해결 과정 최신 정리](#h-오류와-해결-과정-최신-정리)
- [I. 최종 판넬 / 발표 / 보고서 검토](#i-최종-판넬--발표--보고서-검토)
- [J. Codex / Antigravity / 개발 프롬프트 최신 정리](#j-codex--antigravity--개발-프롬프트-최신-정리)
- [K. 운영 인프라 확정 정리](#k-운영-인프라-확정-정리)
- [최신 기준 요약본](#최신-기준-요약본)

---

## 0. 현재 기준 8개 markdown 파일 역할 및 전체 구조

| 순서 | 파일명 | 역할 | 주요 근거 영역 |
| --- | --- | --- | --- |
| 1 | `PROJECT_OVERVIEW.md` | 5개 영역(back/front/esp/pi/ubuntu) 전체 아키텍처, 통신 방향, 폴더 구조, 운영 흐름 | 전체 시스템 |
| 2 | `FUNCTIONAL_SPECIFICATION.md` | 기능 ID별 명세, 구현 상태, 계약 불일치(GAP-01~07) | 기능 전체 |
| 3 | `API_SPECIFICATION.md` | HTTP 인터페이스, 인증, 공통 응답, Enum, endpoint별 DTO 명세 | REST 계약 |
| 4 | `BACKEND.md` | Spring Boot 백엔드 코드 구조, Controller/Service/Repository/Entity, JPA, JWT, S3 | 백엔드 |
| 5 | `FRONTEND.md` | Flutter 앱 구조, 화면 흐름, 모델/서비스, MJPEG 스트림 표시 | 프론트엔드 |
| 6 | `ESP.md` | ESP32 펌웨어(`src/main.cpp`), GPIO 34 토양수분, Wi-Fi POST | ESP32 |
| 7 | `PI.md` | Raspberry Pi Python 코드, 센서/카메라/GPIO/명령 워커/AI trigger | Raspberry Pi |
| 8 | `UBUNTU_GREENLINK_AI.md` | FastAPI AI Worker, rembg, OpenAI Images edit, S3 업로드, 백엔드 callback | AI 이미지 |

### 0.1 핵심 통신 구조 (운영 확정판)

```text
[앱/웹 사용자]
  → Cloudflare (DNS 프록시)
  → AWS Lightsail Nginx : 443 (Certbot HTTPS, 80→443 redirect)
  → Spring Boot Backend : 127.0.0.1:8080  (마지막 운영 확인: screen에서 java -jar 수동 실행)
      → MySQL (JPA)
      → S3 (원본 greenlink/userplant/..., AI 결과 greenlink/ai/userplant/...)
      → DeviceCommand 생성(PENDING)

ESP32 ──X-DEVICE-KEY HTTP POST──► Backend (토양수분, 10분 주기)
Raspberry Pi ──X-DEVICE-KEY HTTP POST + 명령 polling(3초)──► Backend(8080 직접)
Pi ──POST /process──► Ubuntu AI Worker(9000 직접) ──OpenAI gpt-image-1.5 edit──► S3
                                                  └─POST /api/ai/plant-images/{id}/result + X-AI-Worker-Secret──► Backend
Flutter ──직접 MJPEG GET──► Pi Flask stream server(0.0.0.0:8000)
```

> ESP가 Pi를 거쳐 전송된다는 코드는 없습니다. ESP는 백엔드에 직접 POST하며, Pi는 별도로 환경 센서·카메라·릴레이를 담당합니다. (근거: `PROJECT_OVERVIEW.md`, `ESP.md`, `PI.md`)

---

## A. 프로젝트 최신 통합 문서

### A.1 프로젝트 개요

- **공식명**: GreenLink (판넬 표기 GREEN-LINK)
- **부제**: "앱 속 반려식물과 현실 식물을 연결하는 IoT 기반 식물 성장 서비스"
- **팀원**: 안광은, 김민제 / **지도교수**: 김세진 / **참여기업**: 필로
- **이벤트**: 2026년 봄학기 캡스톤 축제 [캡스톤 디자인2]

근거: 판넬 자료, `PROJECT_OVERVIEW.md` "프로젝트 목적"

### A.2 프로젝트 핵심 목적

`PROJECT_OVERVIEW.md` "프로젝트 목적":

> GreenLink는 사용자가 앱에서 식물을 심고 성장 상태를 확인하며, 실제 재배 장치에서 수집되는 환경/토양수분 데이터와 사진을 바탕으로 급수·조명 제어 및 AI 이미지 결과를 이용하는 서비스다.

`FUNCTIONAL_SPECIFICATION.md` "2. 시스템 목적" 핵심:

1. 계정 생성 + 씨앗/화분/영양제 기반 식물 육성
2. 온도/습도/조도/토양수분 앱 조회
3. 수동 또는 설정 기반 자동화로 물주기/조명 명령 생성
4. Raspberry Pi가 펌프·조명 제어 및 결과 보고
5. 식물 사진을 원본 및 AI 스타일 변환 결과로 앱 표시
6. 출석, 수확, 퀘스트 보상, 수확 도감 제공

### A.3 현재 실제 기준으로 확정된 기능 (현재 기준 반영)

| ID | 기능명 | 상태 | 주요 근거 |
| --- | --- | --- | --- |
| F-AUTH-01 | 일반 회원가입/로그인 | 구현됨 | `AuthService`, 인증 화면 |
| F-AUTH-02 | Kakao/Google OAuth 로그인 | 구현됨(운영 동작 확인) | OAuth service/client, Flutter auth |
| F-USER-01 | 내 정보/닉네임 수정 + 비밀번호 변경 + 회원 탈퇴 + 서버 로그아웃 | 구현됨 | `UserController`, `UserService`, tokenVersion 기반 토큰 무효화 |
| F-PLANT-01 | 식재, 성장 표시, 별명, 수확 | 구현됨 | `UserPlantService`, Flutter screens |
| F-ITEM-01 | 인벤토리, 화분, 영양제 | 구현됨 | `UserItemService` |
| F-QUEST-01 | 퀘스트 목록/상세/보상 | 구현됨(WATERING/GROW_PLANT 진행 연결) | `UserQuestService` |
| F-ATTEND-01 | 출석과 연속 출석 | 구현됨 | `AttendService` |
| F-COLL-01 | 수확 도감 | 구현됨 | `CollectionService` |
| F-IOT-SETUP-01 | 공간/장치/펌프 연결 구성 | 구현됨(권한 범위 주의) | `IotSetupService` |
| F-SENSOR-01 | ESP32 토양 수분 수집 | 구현됨 | `main.cpp`, `IotDeviceDataService` |
| F-SENSOR-02 | Pi 환경(DHT22/BH1750) 수집 | 구현됨 | `sensor_*.py`, `IotDeviceDataService` |
| F-CAMERA-01 | MJPEG stream 및 원본 사진 업로드 | 구현됨 | `stream_server.py`, `camera_main.py` |
| F-CONTROL-01 | 수동 물주기/조명 명령 생성·실행 | 구현됨 | `IotAppService`, `command_worker.py` |
| F-AUTO-01 | 설정 기반 자동 물주기/조명 | 구현됨 | `AutomationService` |
| F-AUTO-02 | 데이터 기반 자동화 임계치 산출(통계/규칙) | 구현됨(ML 모델 파일 없음) | `AutomationLearningService` |
| F-AI-01 | 사진 AI 스타일 변환 | 구현됨(실패 복구 미확인) | AI Python 코드 + AiPlantImageService |
| F-ADMIN-01 | 마스터/사용자/장치 관리 (REST + Thymeleaf) | 부분 구현(로그인은 JWT cookie 방식) | `AdminController`, `AdminWebController` |

### A.4 부분 구현/계약 불일치 기능 (GAP-01~07) — 코드 확정

| ID | 내용 | 상태 |
| --- | --- | --- |
| GAP-01 | `POST /api/user-plants/{id}/iot/refresh` endpoint, `CommandType.SENSOR_REFRESH`, Pi 기존 분기 연결 | 해소 |
| GAP-02 | GAP-01과 동일 작업으로 Backend 명령 생성 경로와 Pi `SENSOR_REFRESH` 분기 연결 | 해소 |
| GAP-03 | `AutomationSetting.wateringSafetyEnabled` 필드/DTO와 수동 급수 400 차단은 반영. 자동 급수는 일반 effective threshold를 먼저 검사해 기본/RULE_BASED에서 safety 전용 분기가 사실상 도달하지 않고 학습 임계치 조합에서만 제한적으로 도달 | 부분 해소 |
| GAP-04 | Backend `DeviceCommand`와 Pi 실행 경계가 WATER를 `0 < durationSeconds <= 1`로 제한. Pi는 key가 없을 때만 1초를 사용하고 invalid 값은 펌프 미호출·FAILED 처리 | 해소 — 1초 fail-close 상한 구현 |
| GAP-05 | WATER SUCCESS 시 `TargetType.WATERING` 증가, 수확 시 `TargetType.GROW_PLANT` 증가 | 해소 |
| GAP-06 | Spring form login 비활성. 단, `/api/auth/login` AJAX + `jwt_token` cookie 인증은 구현됨 | **부분 정정** → "JWT cookie 기반 부분 구현, 보안 정책 정리 필요" |
| GAP-07 | `camera_snapshot_main.py` legacy 파일 삭제 완료 | 해소 |

### A.5 과거 문서에는 있었으나 현재 기준에서 없거나 정정된 기능

| 과거 표현 | 현재 기준 결과 | 분류 |
| --- | --- | --- |
| FCM 푸시 알림 | 사용자가 Apple 개발자 계정 부재로 미구현 확정. `Firebase.initializeApp`/토큰 저장/수신 handler 모두 없음 | **미구현 확정** |
| AWS Lightsail | 코드 명시 없으나 사용자 운영 확인 (Backend+AI Worker가 Lightsail에서 실행) | **사용자 운영 확인** |
| Nginx + Certbot HTTPS | 코드 외부지만 운영 확인(80/443, greenlink site, 인증서, 8080 proxy) | **사용 확정(운영 확인)** |
| Cloudflare | 코드 외부지만 운영 확인(서버 도메인 + 카메라 도메인). Pi에 cloudflared 실행 | **사용 확정(운영 확인)** |
| AI에서 transparent/png 파라미터 | 코드에 없음. 투명화는 `remove_pot` 전처리 단계 | **정정** |
| 알파 마스크 합성 / pot 합성 | `alpha_composite.py`, `compose_pot.py`, `pot_base.png`, `ai_background_remove.py` 삭제 완료 | **삭제 완료** |
| ESP32 직접 펌프 제어 | ESP에 펌프 GPIO 없음. Pi가 담당 | **폐기/미적용** |
| 자체 학습 ML 모델 | dataset/train script 없음. 통계/규칙 기반 | **폐기/미적용** |
| `camera_main.py --plant` CLI | `argparse`/`sys.argv` 없음. 식물 구분은 `config.py` 고정 상수 | **미지원 확정** |
| 친구/공유/그림판 | 관련 도메인 코드 없음 | **폐기/미적용** |
| 팬 제어 | CommandType/GPIO 어디에도 없음 | **미적용** |
| `camera_snapshot_main.py` | legacy 파일 삭제 완료(GAP-07 해소) | **삭제 완료** |
| 백엔드가 AI Worker 직접 호출 | Pi `uploader.py`/`ai_trigger.py`가 호출 | **정정** |

### A.6 중간에 바뀐 결정사항

| 항목 | 과거 | 현재 기준 | 근거 |
| --- | --- | --- | --- |
| ESP32-Pi 연결 | ESP→Pi 중계 | ESP가 백엔드 직접 POST | PROJECT_OVERVIEW/ESP/PI |
| AI 변환 | alpha 합성/AI에 rembg 재적용 | rembg+하단 24% trim 전처리 → gpt-image-1.5 edit → PNG → S3 | UBUNTU_GREENLINK_AI + 코드확정 |
| 화분 제거 | 학습 segmentation | 규칙 기반 하단 24% 투명화(`FALLBACK_TRIM_RATIO=0.24`) | remove_pot.py |
| 자동화 모델 | ML 학습 | 통계/규칙 임계치 산출 | AutomationLearningService |
| 카메라 진입점 | camera_snapshot_main.py | camera_main.py(MJPEG 프레임 추출) | PI.md |
| 관리자 로그인 | (미정) | API 로그인 + jwt_token cookie 인증 | GAP_DECISION_REVIEW §3 |
| 배포 | (미정) | Lightsail + Cloudflare + Nginx + Certbot, Backend는 JAR 수동 전송 후 `screen`에서 `java -jar` 실행 | GAP_DECISION_REVIEW §11/§13 |

### A.7 전체 시스템 구조

| 영역 | 역할 | 핵심 통신/저장 |
| --- | --- | --- |
| `greenlink_front` | 로그인, 식물/인벤토리/도감/퀘스트/IoT/자동화 UI | HTTPS REST, 공개 MJPEG stream |
| `greenlink_back` | 비즈니스 API, 인증, JPA 저장, 자동화 판단, 관리자 화면 | Spring MVC, MySQL/JPA, S3, JWT |
| `greenlink_esp` | 개별 식물 토양수분 측정·업로드 | ADC, Wi-Fi HTTP POST |
| `greenlink_pi` | 환경 측정, 카메라/MJPEG, 사진 업로드, 릴레이 명령 수행, AI 호출 | GPIO/I2C/DHT/Picamera2, HTTP |
| `greenlink_ubuntu` | 원본 사진 AI 스타일 변환 + S3/백엔드 반영 | FastAPI, OpenAI Images, rembg, S3, HTTP callback |

### A.8 백엔드 구조

- **언어/런타임**: Java 17 toolchain
- **프레임워크**: Spring Boot 4.0.6, Spring Web MVC
- **데이터**: Spring Data JPA, MySQL
- **인증**: Spring Security, JWT(jjwt), BCrypt, OAuth(Kakao/Google)
- **파일**: AWS SDK S3
- **화면**: Thymeleaf 관리자 템플릿

```text
greenlink_back/src/main/java/com/greenlink/greenlink/
├── GreenlinkApplication.java
├── common/      # ApiResponse, BaseEntity, GlobalExceptionHandler
├── config/      # S3Config, SecurityConfig
├── security/    # JwtAuthenticationFilter, JwtTokenProvider, CustomUserDetails(Service)
├── controller/  # Auth, User, Home, Plant, Item, Quest, UserPlant, UserItem, UserQuest,
│                # Attend, Collection, Automation, IotApp, IotDevice, IotSetup,
│                # AiPlantImage, Admin, AdminWeb
├── service/     # Auth, Home, UserPlant, UserItem, UserQuest, Attend, Collection,
│                # IotDeviceData, IotApp, IotCommand, IotSetup, Automation,
│                # AutomationLearning, AiPlantImage, S3Upload, oauth/
├── repository/
├── domain/      # user/, plant/, item/, quest/, attend/, iot/, ai/, automation/
└── dto/         # iot/, ai/
```

### A.9 프론트엔드 구조

- Flutter/Dart(SDK `^3.9.2`), Material UI
- HTTP: `http` 패키지 기반 REST + MJPEG byte stream 파싱
- 토큰 저장: `shared_preferences`
- 소셜: Kakao Flutter SDK, Google Sign-In
- 알림: `firebase_core`/`firebase_messaging` **의존성만 선언, 실제 사용 흐름 없음 → 미구현 확정**
- 상태관리: 화면별 `StatefulWidget`/`setState`+`GlobalKey` (`provider`는 선언만)
- 테스트: `iot_water_shortage_test.dart` 8개 + `api_contract_model_test.dart` 5개 = 13개. 현재 검증 환경에 Flutter/Dart SDK가 없어 이번 실행은 미수행

```text
greenlink_front/lib/
├── main.dart
├── core/{config/camera_config.dart, constants/{api_paths, stream_urls, iot_thresholds}.dart,
│         network/{api_client, api_response, token_storage}.dart, utils/, widgets/}
├── models/   # auth, home, user_plant, user_item, collection, quest, attend, iot, automation
├── services/ # auth, home, user_plant, user_item, collection, quest, attend, iot, automation
├── screens/  # splash_page, main_page, settings_page, auth/, home/, inventory/, collection/,
│             # quest/, attend/, user_plant/, iot/
├── widgets/  # mjpeg_stream_view.dart 등
└── theme/app_theme.dart
```

### A.10 IoT — Raspberry Pi 구조

파일: `config.py`, `sensor_service.py`, `sensor_uploader.py`, `sensor_main.py`, `api_client.py`, `relay_control.py`, `command_worker.py`, `stream_server.py`, `stream_snapshot_service.py`, `camera_service.py`, `camera_main.py`, `uploader.py`, `ai_trigger.py`, `run_sensor.sh`, `run_camera.sh`, `run_command.sh`

| 핀/버스 | 대상 | 역할 |
| --- | --- | --- |
| BCM GPIO 4 | DHT22 | 온습도 |
| I2C bus 1 / 0x23 | BH1750 | 조도 |
| BCM GPIO 27 | 조명 릴레이 | LED on/off |
| BCM GPIO 22 | 바질 펌프 릴레이 | 물주기 |
| BCM GPIO 23 | 해바라기 펌프 릴레이 | 물주기 |
| Camera | Pi Camera | MJPEG + 사진 |

릴레이는 Active LOW. Stream route: `/`, `/health`, `/stream.mjpg`, `/stream/sunflower.mjpg`, `/stream/basil.mjpg`. crop: 해바라기=오른쪽 절반, 바질=왼쪽 절반. 스냅샷 출력 1080x1620. stream_server는 180도 회전 적용, camera_main은 회전 없음. command polling 3초, 센서 600초.

### A.11 IoT — ESP32 구조

- 보드 ESP32(`esp32dev`), Arduino, PlatformIO
- 파일: `platformio.ini`, `src/main.cpp`
- GPIO 34 ADC 12bit, ADC_11db, 10회 평균 → DRY/WET calibration 0~100%
- 전송: 부팅 직후 + 10분(`SEND_INTERVAL_MS`), `POST /api/iot/esp/soil-moisture`
- Header: `Content-Type: application/json`, `X-DEVICE-KEY`
- Body: `{"soilMoistureRaw": <int>, "soilMoisturePercent": <double>}` (measuredAt 없음 → 서버 시각)
- 펌프/릴레이 제어 없음. Wi-Fi 60회 시도 후 `ESP.restart()`

### A.12 AI 이미지 처리 구조 (확정값 반영)

파일: `ai_worker_api.py`, `process_one.py`, `job_name.py`, `remove_pot.py`, `openai_transform.py`, `s3_client.py`, `style_plant.png` (활성). `ai_background_remove.py`, `alpha_composite.py`, `compose_pot.py`, `pot_base.png` 는 **삭제 완료**.

**확정 파이프라인**:

```text
1. Pi 원본 업로드 → plantImageId, userPlantId, imageUrl 수신
2. ai_trigger.py → POST {AI_WORKER_URL}/process
3. ai_worker_api.py: Pydantic 검증 → BackgroundTask 등록 → 즉시 PROCESSING 응답
4. process_one.py:
   a. s3_client.download_image():
      - configured bucket/region의 정확한 HTTPS virtual-host URL과 greenlink/userplant/{단일 파일}만 허용
      - boto3 get_object 후 확장자·ContentType·ContentLength·실제 stream 길이(최대 20MiB) 검증
      - 검증 성공 시에만 inputs/<name>으로 원자적 저장
   b. remove_pot.py (투명화는 여기서):
      - rembg MODEL_NAME="u2netp" 배경 제거
      - ALPHA_THRESHOLD=12 로 알파 mask 판정
      - FALLBACK_TRIM_RATIO=0.24 (객체 하단 24%) 투명화
      - BOTTOM_PAD_PX=28 하단 padding
   c. openai_transform.py:
      client.images.edit(
        model="gpt-image-1.5",
        image=[전처리PNG, style_plant.png],
        prompt=PROMPT,            # 형태 보존 / 스타일 색감·질감 참고 / 화분·배경 생성 금지
        input_fidelity="high",
      )
      # background / output_format 파라미터 없음
      → 반환 base64를 PNG로 저장
   d. s3_client.py: 최종 PNG를 S3에 PUT (key: greenlink/ai/userplant/{원본stem}.png)
   e. save_backend_result(): POST /api/ai/plant-images/{id}/result { "finalAiUrl": ... } + X-AI-Worker-Secret
5. Backend AiPlantImage 저장 (AiImageStatus 기본값 SUCCESS)
```

> **중요**: "OpenAI 단계에서 투명 PNG를 생성한다"는 표현은 **오류**. 투명화는 `remove_pot.py` 전처리에서 수행되며, OpenAI 호출에 `background`/`output_format` 파라미터는 없습니다.
>
> 원본 다운로드는 임의 HTTP 요청이 아니다. URL/key 또는 S3 metadata/stream 검증 실패 시 OpenAI 처리 전에 중단하며 부분 파일을 남기지 않는다.

### A.13 Ubuntu GreenLink AI 서버 구조

- 실행: `greenlink-ai.service` (systemd), `uvicorn ai_worker_api:app --host 0.0.0.0 --port 9000` (HTTP)
- `/health` 정상, `/` route 없음(404 정상)
- 영속 큐 없음(FastAPI BackgroundTasks). 실패 복구/상태조회 API 없음
- 9000 포트 Lightsail 방화벽에서 Any IPv4 공개 → 제한 필요

### A.14 배포 / 서버 / AWS / Nginx / Cloudflare 구조 (운영 확정)

| 구분 | 확정 내용 |
| --- | --- |
| 인프라 | AWS Lightsail Ubuntu (Backend + greenlink_ubuntu 실행) |
| 외부 노출 | Cloudflare → Nginx(443, Certbot HTTPS, 80→443 redirect) → Spring Boot 127.0.0.1:8080 |
| Backend 실행 | `screen` 세션에서 `java -jar` 수동 실행, 8080. Backend systemd unit은 마지막 확인에서 없음 |
| AI Worker 실행 | `greenlink-ai.service` systemd, 9000 |
| Pi 실행 | `greenlink-command.service`(command_worker.py), `greenlink-stream.service`(stream_server.py), 둘 다 enabled/running, Restart=always/RestartSec=5 + cron(센서 10분, 카메라 09·21시) |
| secret 위치 | 마지막 운영 확인 당시 배포 JAR 내부 `BOOT-INF/classes/yaml/application-keys.yaml`에 DB/AWS/OAuth secret이 포함돼 있었음. 현재 소스의 S3 client는 이 AWS key property를 사용하지 않고 기본 credential chain을 사용하므로, 재배포 시 DB/OAuth/JWT도 외부화하고 legacy AWS key를 산출물에서 제거해야 함 |
| CI/CD | 미사용. Git/GitHub만 사용. 로컬 Gradle build → JAR 수동 전송 → `screen`에서 수동 실행 |
| Cloudflare cloudflared | Lightsail에는 미실행, Pi에 실행 중(127.0.0.1:20241) |

### A.15 실행 명령어

| 영역 | 명령 |
| --- | --- |
| Backend | `cd greenlink_back && ./gradlew bootRun` / `./gradlew test` / `./gradlew bootJar` (마지막 운영 확인: `screen`에서 `java -jar <jar>`) |
| Frontend | `cd greenlink_front && flutter pub get && flutter run` / `flutter test` / `flutter build <platform>` |
| ESP | `cd greenlink_esp && pio run && pio run -t upload && pio device monitor` |
| Pi 센서(1회) | `python sensor_main.py` (운영: cron `run_sensor.sh` 10분) |
| Pi 명령 워커 | `python command_worker.py` (운영: `greenlink-command.service`) |
| Pi 스트림 | `python stream_server.py` (운영: `greenlink-stream.service`, 0.0.0.0:8000) |
| Pi 카메라 | `python camera_main.py` (운영: cron `run_camera.sh` 09·21시) |
| AI Worker | `uvicorn ai_worker_api:app --host 0.0.0.0 --port 9000` (운영: `greenlink-ai.service`) |
| AI Worker CLI | `python process_one.py --url <url> --name <name> --plant-image-id <id>` |
---

## B. 현재 기준 문서-과거 문서 정합성 검증 보고서

### B.1 현재 기준과 일치하는 내용

| 구분 | 과거 markdown 내용 | 현재 기준 근거 | 판정 |
| --- | --- | --- | --- |
| 시스템 구성 | Flutter+Spring Boot+MySQL+Pi+ESP32+Ubuntu AI | PROJECT_OVERVIEW | 일치 |
| 백엔드 스택 | Spring Boot, JPA, JWT, BCrypt, MySQL | BACKEND.md | 일치 |
| 프론트 기술 | Flutter, Dart, Kakao SDK, Google Sign-In | FRONTEND.md | 일치 |
| ESP32 통신 | Wi-Fi HTTP POST + 장치 키 | ESP.md | 일치 |
| Pi 환경 센서 | DHT22(GPIO4), BH1750(0x23) | PI.md | 일치 |
| Pi GPIO | LED 27, 펌프 22/23, active-low | PI.md | 일치 |
| 카메라 | Pi Camera + Picamera2 + Flask MJPEG | PI.md | 일치 |
| AI 변환 | rembg → OpenAI → S3 → callback | UBUNTU_GREENLINK_AI | 일치 |
| S3 사용 | 원본/AI 결과 S3 저장 | BACKEND/UBUNTU | 일치 |
| 자동화 트리거 | ESP 후 급수, Pi 후 조명 평가 | AutomationService | 일치 |
| 명령 polling | Pi가 pending polling + PATCH | PI/API_SPEC | 일치 |
| AI callback | POST /api/ai/plant-images/{id}/result + `X-AI-Worker-Secret` | API_SPEC 6.9 | 일치 |
| MJPEG 직접표시 | 앱이 byte stream 파싱 | FRONTEND | 일치 |
| 퀘스트 진행 | ATTEND/HARVEST/WATERING/GROW_PLANT 진행 | FUNCTIONAL_SPEC | 일치 |
| 회원가입 초기지급 | 기본 SEED+POT+업적 퀘스트 | AuthService | 일치 |
| aiImageUrl | 앱이 AI 이미지 우선 표시 | API_SPEC 6.5 | 일치 |
| 자동화 통계기반 | ML 파일 없음, 임계치 통계 | FUNCTIONAL_SPEC/BACKEND | 일치 |

### B.2 현재 기준과 충돌하는 내용 (정정 결과 반영)

| 과거 내용 | 현재 기준 | 판정 |
| --- | --- | --- |
| ESP→Pi 중계 | ESP 백엔드 직접 POST | 현재 기준 우선(폐기) |
| AI에 transparent/png 파라미터 | OpenAI 호출에 없음, 투명화는 remove_pot 전처리 | 정정 |
| alpha/pot 합성 | legacy 파일 삭제 완료 | 폐기/삭제 완료 |
| 급수 최대 1초 | Backend와 Pi가 `0 < durationSeconds <= 1`을 강제. key 누락만 1초 fallback, invalid 값은 펌프 미호출·FAILED | GAP-04 해소 / 물리 유량 교정은 잔여 |
| camera_snapshot 진입점 | legacy 파일 삭제 완료(GAP-07 해소), active는 camera_main | 현재 기준 우선 |
| camera_main `--plant` | argparse 없음, config 고정 | 미지원 확정 |
| 센서 새로고침 동작 | GAP-01/02 해소, Backend endpoint/SENSOR_REFRESH 명령 생성 구현 | 현재 기준 우선 |
| wateringSafetyEnabled 동작 | Backend 설정·수동 급수 차단 반영. 자동 safety는 이중 임계치/조건 순서 정리 필요 | 부분 반영 |
| WATERING/GROW_PLANT 진행 | WATER SUCCESS와 수확 시점에 연결 | 현재 기준 우선 |
| 관리자 로그인 미구현 | jwt_token cookie 기반 부분 구현(GAP-06) | **부분 정정** |
| AWS Lightsail 미확인 | 사용자 운영 확인 | 정정(사용 확정) |
| Nginx/Certbot 미확인 | 사용자 운영 확인 | 정정(사용 확정) |
| Cloudflare 근거 없음 | 사용자 운영 확인(서버+카메라 도메인) | 정정(사용 확정) |
| FCM 푸시 동작 | 미구현 확정(Apple 계정 부재) | 정정 |
| 백엔드가 AI 호출 | Pi가 호출 | 정정 |
| 데이터 ID 예시(growSpaceId=2 등) | 운영 데이터, 코드 고정값 아님 | 운영값 |
| 친구/공유/그림판 | 코드 없음 | 폐기/미적용 |

### B.3 과거에는 있으나 현재 기준에 없는 내용 (최종 분류)

| 기능/내용 | 현재 결과 | 분류 |
| --- | --- | --- |
| FCM 푸시 | 의존성만, 사용 흐름 없음 | **미구현 확정** |
| Cloudflare | 운영 사용 확인, 설정값은 코드 외부 | **사용자 운영 확인** |
| Nginx/Certbot 설정 파일 | 운영 서버에 존재, 저장소엔 없음 | **운영 인프라(코드 외부)** |
| AWS Lightsail | 운영 사용 확인 | **사용자 운영 확인** |
| systemd/cron(Pi) | 운영 확인됨 | **사용자 운영 확인** |
| 개발 프롬프트 | 제품 기능 아님 | **개발 보조자료** |
| 친구/공유/그림판/채팅 | 코드 없음 | **폐기/미적용** |
| ESP32 직접 펌프 | 코드 없음 | **폐기/미적용** |
| 자체 ML 모델 | 없음 | **폐기/미적용** |
| pot/alpha 합성 | legacy 파일 삭제 완료 | **삭제 완료** |
| camera_snapshot_main 진입점 | legacy 파일 삭제 완료 | **삭제 완료** |
| 백엔드 AI 직접 호출 | 코드 없음 | **폐기/미적용** |

### B.4 현재 기준에는 있으나 과거 markdown에 약하게 다뤄진 내용

| 현재 기준 내용 | 근거 | 보완 |
| --- | --- | --- |
| AutomationLog + 로그 API | API_SPEC 5.3 | 최근 30개 판단 로그 조회 |
| AutomationModel 상태/학습 API | API_SPEC 5.3 | INSUFFICIENT_DATA/READY/FAILED |
| IotSetupService 구성 API | API_SPEC 5.5/6.8 | grow-space/device/pump-channel |
| 장치 키 응답 노출 제거 | API_SPEC 6.8/11 | DeviceResDto/PumpChannelResDto에서 제거됨 |
| AI callback 인증 | API_SPEC 3.5/11 | `X-AI-Worker-Secret` shared secret header 검증 도입 |
| JWT secret 하드코딩 → JAR 내부 포함 | BACKEND + GAP_REVIEW §13.4 | 외부화 필요 |
| 장치 키 소스 노출 | ESP/PI | provisioning 외부화 |
| GAP-01~07 명시 | FUNCTIONAL_SPEC 17 | 운영 위험 인지 |
| 자동화는 통계/규칙 | FUNCTIONAL_SPEC F-AUTO-02 | "ML 학습" 표현 금지 |
| provider 의존성만 선언 | FRONTEND | "Provider 아키텍처" 표현 금지 |
| JAR 내부 secret/방화벽 공개 | GAP_REVIEW §13.4/13.6 | 신규 보안 위험 |

### B.5 최신화가 필요한 문서 항목 (수정 방향)

| 기존 표현 | 최신화 방향 |
| --- | --- |
| "ESP가 Pi로 데이터 전송" | "ESP는 백엔드 직접 POST, Pi는 카메라/명령 실행 담당" |
| "센서 새로고침 동작" | "Backend endpoint/SENSOR_REFRESH 명령 생성 경로와 Pi 분기 연결 완료" |
| "물주기 자동 제어" | "Backend와 Pi가 WATER를 최대 1초로 fail-close 제한하며, Pi는 duration key가 없을 때만 1초를 사용" |
| "AI가 alpha/화분 합성" | "remove_pot 전처리(rembg+0.24 trim) → gpt-image-1.5 edit 결과 저장 → S3" |
| "백엔드가 AI Worker 호출" | "Pi가 업로드 응답 후 AI Worker /process 호출" |
| "FCM 푸시 알림" | "FCM 의존성만, 초기화/토큰/수신/발송 없음 = 미구현" |
| "Nginx/Certbot/Cloudflare HTTPS" | "Lightsail에서 Cloudflare→Nginx(443,Certbot)→8080 proxy 운영 확인. 코드 외부 인프라" |
| "물주기/식재 퀘스트 진행" | "WATERING은 WATER SUCCESS 시점, GROW_PLANT는 수확 시점에 진행" |
| "관리자 로그인 후 관리" | "API 로그인+jwt_token cookie 기반 부분 구현, 보안 정리 필요" |
| "snapshot 캡처 업로드" | "active는 camera_main(MJPEG 추출), camera_snapshot_main legacy 파일은 삭제 완료" |
| "Lightsail에서 운영" | "사용자 운영 확인. 코드 명시 없음 → 운영 문서로 분리" |

---

## C. 기능별 최신 구현 현황

> 형식: 현재 상태 / 목적 / 근거 / 관련 API·DB·화면·코드 / 흐름 / 차이 / 최신 기준

### C.1 로그인 / 회원가입 — 현재 기준 반영
- 근거: FUNCTIONAL_SPEC F-AUTH-01, API_SPEC 6.1, `AuthController`/`AuthService`, Flutter `auth_service.dart`/`login_page`/`signup_page`
- API: `POST /api/auth/signup`, `POST /api/auth/login`, `PATCH /api/users/me/password`, `DELETE /api/users/me`, `POST /api/users/me/logout`
- DB: `User`, `UserItem`(초기), `UserQuest`(업적)
- 흐름: 가입 시 이메일 중복검사 → BCrypt → User 저장 → 기본 SEED+POT 지급 → 업적 퀘스트 생성. 로그인 시 BCrypt 검증 → tokenVersion claim 포함 JWT 발급 → shared_preferences 저장. 비밀번호 변경/탈퇴/로그아웃은 tokenVersion 증가로 기존 JWT 무효화
- 주의: 기본 마스터 아이템(SEED/POT) 미생성 시 409
- 비밀번호 변경: LOCAL 유저만 가능, 현재 비밀번호 검증 후 새 비밀번호(4자 이상) 저장. OAuth 유저는 차단

### C.2 JWT 인증 — 현재 기준 반영
- 근거: BACKEND "JwtAuthenticationFilter/JwtTokenProvider", API_SPEC 3.4
- 전달: `Authorization: Bearer <token>` 또는 `jwt_token` cookie
- 흐름: 발급(tokenVersion claim 포함) → ApiClient가 헤더 부착 → 필터가 헤더/쿠키에서 추출 → 서명/만료 검증 → DB `User.tokenVersion`과 토큰 claim 비교 → 일치 시 SecurityContext 설정
- 무효화: 로그아웃/탈퇴/비밀번호 변경 시 `User.tokenVersion`이 증가하며 기존 토큰은 불일치로 401 처리
- 주의: secret이 현재 JAR 내부 application-keys.yaml에 포함 → 외부화 필요

### C.3 OAuth 로그인 (Kakao/Google) — 현재 기준 반영(운영 동작 확인)
- 근거: FUNCTIONAL_SPEC F-AUTH-02, API_SPEC 6.1, `service/oauth/`, Kakao SDK/Google Sign-In
- API: `POST /api/auth/oauth/kakao`, `POST /api/auth/oauth/google`
- 요청: `{ "code": "...", "redirectUri": "..." }` → 응답 일반 로그인과 동일
- 흐름: 앱에서 code 획득 → Backend가 provider 토큰/프로필 획득 → provider 식별자(`provider`,`providerId`)로 조회/생성 → 초기 보정 → JWT
- 주의: OAuth DTO validation 없음. client 설정은 JAR 내부 application-keys.yaml에 포함(운영 동작 확인)

### C.4 사용자 식물 조회 — 현재 기준 반영
- API: `GET /api/user-plants?status=`, `GET /api/user-plants/{id}`
- DB: `UserPlant`, `Plant`
- 흐름: 소유권 검증 → 조회 시점 GROWING→HARVESTABLE 자동 갱신 → 상태/경과일/이미지/장착화분 응답

### C.5 식물 심기 — 현재 기준 반영
- API: `POST /api/user-plants` (`{userItemId, nickname?}`)
- DB: `UserPlant`(생성), `UserItem`(SEED→USED)
- 흐름: OWNED SEED + 연결 Plant 검증 → UserPlant(GROWING, plantedAt, expectedHarvestableAt) 생성 → SEED USED
- 주의: GROW_PLANT 퀘스트는 현재 식재 시점이 아니라 수확 시점에 진행

### C.6 아이템 지급 — 현재 기준 반영
- 회원가입 응답 `grantedItems[]`; 퀘스트 보상 `POST /api/user-quests/{id}/reward`
- DB: `UserItem`, `Quest`, `UserQuest`, `Item`
- 흐름: 가입 시 기본 SEED+POT 생성; 보상 시 ACHIEVABLE 검증 후 수량만큼 OWNED UserItem 생성

### C.7 인벤토리 / 아이템 장착 — 현재 기준 반영
- API: `GET /api/user-items`, `POST .../equip-pot`, `.../unequip-pot`, `.../use-nutrient`
- 규칙: OWNED POT만 장착(기존 EQUIPPED 자동 해제), EQUIPPED POT만 해제, OWNED NUTRIENT만 사용
- **영양제 효과 확정**: `useNutrient()`는 UserItem을 USED로 바꾸고 대상 식물만 연결. 성장일/수확가능일 변화 **없음**

### C.8 퀘스트 — 현재 기준 반영
- API: `GET /api/user-quests`, `GET /api/user-quests/{id}`, `POST .../reward`
- Enum: QuestType(DAILY/WEEKLY/MONTHLY/ACHIEVEMENT), ResetCycle(DAILY/WEEKLY/MONTHLY/NONE), TargetType(ATTEND/WATERING/GROW_PLANT/HARVEST), 상태(IN_PROGRESS/ACHIEVABLE/COMPLETED/EXPIRED)
- 진행 호출: `QuestProgressService.increaseProgress()`는 ATTEND(`AttendService`), HARVEST/GROW_PLANT(`UserPlantService.harvestUserPlant()`), WATERING(`IotCommandService` WATER SUCCESS)에서 호출

### C.9 최신 센서 데이터 조회 — 현재 기준 반영
- API: `GET /api/user-plants/{id}/iot/latest`
- 응답: `growSpace`, `environment`(공간별 최신 Pi), `soil`(식물별 최신 ESP), `latestImage{imageUrl, aiImageUrl, capturedAt}`
- 규칙: 식물이 GrowSpace 미연결 시 처리 불가, 각 영역 데이터 없으면 null

### C.10 물부족 알림 / 수분 과다 차단
- 물부족 UI: 부분 확인 (Flutter `iot_thresholds.dart` 상수 + 관련 테스트 8개). Backend 자동급수 설정과 별개 상수
- 수분 과다 차단(`wateringSafetyEnabled`): Backend 설정과 수동 급수 차단에 반영. 자동 급수는 일반 effective threshold가 먼저 적용되어 기본/RULE_BASED에서 safety 전용 분기가 사실상 도달하지 않고 학습 임계치 조합에서만 제한적으로 도달
- 백엔드 푸시: **미구현**

### C.11 원격 물주기(수동 급수) — 현재 기준 반영
- API: `POST /api/user-plants/{id}/iot/water`
- DB: `DeviceCommand`, `PumpChannel`, `IotDevice`, `UserPlant`
- 흐름: 소유/공간/활성 펌프·Pi 검증 → 진행 중 WATER 없으면 PENDING 생성 → Backend WATER duration 검증 → Pi polling → processing → Pi 실행 직전 duration 재검증 → GPIO on → finally off → complete
- 주의(GAP-04): Backend와 Pi 모두 `0 < durationSeconds <= 1`만 허용한다. Pi는 `durationSeconds` key가 없을 때만 **1초**를 사용한다. null·비수치·bool·NaN/무한대·0 이하·1초 초과 값은 펌프를 호출하지 않고 command를 FAILED로 보고한다.
- 1초는 유량 교정 전 fail-close 상한이다. 실제 안전 시간은 펌프별 유량, 호스 높이, 화분의 안전 급수량·배수 상태를 측정한 뒤 Backend와 Pi를 함께 변경해야 한다.

### C.12 LED 제어 — 현재 기준 반영
- API: `POST .../iot/light/on`, `.../iot/light/off`
- GPIO 27 active-low. 명령 duration은 **null**(LIGHT). 공간 장치이나 중복/cooldown은 식물별 명령 기준(상충 가능성)

### C.13 팬 제어 — 미적용
- CommandType/GPIO/API 어디에도 없음. 현재 프로젝트에 팬 제어 없음

### C.14 센서 새로고침 — 구현 완료(GAP-01/02 해소)
- Flutter `iot_service.dart`가 `POST /iot/refresh` 호출하고 Backend `IotAppController` endpoint가 처리
- Backend는 `CommandType.SENSOR_REFRESH` 명령을 PENDING으로 생성하며, Pi `command_worker.py`의 기존 `handle_sensor_refresh_command()` 분기가 처리
- Flutter 버튼은 요청 중 비활성화하고 2.5초 후 latest를 재조회하며, 진행 중 명령 409를 스낵바로 표시

### C.15 카메라 촬영 — 현재 기준 반영(GAP-07 해소)
- API: `POST /api/iot/plant-images` (multipart)
- 흐름: stream_server 프레임 → camera_main이 추출 → config 고정 crop(해바라기 우/바질 좌) → uploader multipart 업로드(X-DEVICE-KEY) → S3UploadService(20MiB 및 jpg·jpeg·png·webp와 MIME의 정확한 대응 검증) → PlantImage 저장 → ai_trigger 호출 → 로컬 crop 삭제

### C.16 실시간 스트리밍 — 현재 기준 반영(인증 없음)
- Pi stream_server.py Flask MJPEG (0.0.0.0:8000). route 5개. Flutter `MjpegStreamView`가 byte stream 파싱
- 주의: stream 인증 없음. 외부 노출은 Pi cloudflared tunnel 사용(세부 추가 확인)

### C.17 이미지 업로드 — 현재 기준 반영
- `POST /api/iot/plant-images` → S3UploadService → PlantImage. key: `greenlink/userplant/{storedFilename}`

### C.18 AI 이미지 변환 — 현재 기준 반영(확정값)
- 근거: FUNCTIONAL_SPEC F-AI-01, UBUNTU_GREENLINK_AI + 코드 확정
- 흐름: A.12 참조. 핵심: configured S3 URL/key 검증 → boto3 `get_object`와 MIME/확장자/20MiB 선언·실제 크기 검증 → rembg(u2netp)+하단 24% trim 전처리 → `gpt-image-1.5` edit(image 2장, prompt, input_fidelity="high") → PNG → S3 → callback
- 정정: OpenAI 호출에 background/output_format 없음. 투명화는 전처리 단계
- 주의: 원본 검증 실패는 OpenAI 처리 전에 중단한다. 실패 복구/상태조회/재시도는 없고 Backend callback은 `X-AI-Worker-Secret` header 인증 적용

### C.19 S3 저장 — 코드 구현 완료 / live 재확인 필요
- 원본: Backend(`greenlink/userplant/{storedFilename}`, storedFilename = `user-plant-{id}-{yyyyMMdd-HHmmss}-{uuid8}.{ext}` 또는 `grow-space-{ts}-{uuid8}.{ext}`)
- AI Worker: boto3 `get_object`로 원본을 읽고 결과를 `greenlink/ai/userplant/{원본stem}.png`에 PUT. 명시적 access/secret 없이 기본 credential provider chain 사용
- 과거 운영 기록에는 업로드·저장·앱 조회 성공이 있으나, 이번 확인 시 configured bucket이 없어 새 `get_object` 경로의 live 권한은 검증하지 못했다. bucket 재생성 후 Worker 서비스와 같은 identity·bucket·region 및 알려진 object로 smoke가 필요하다.
- private bucket에서도 Worker SDK 읽기는 가능하지만 Flutter의 naked `imageUrl`/`aiImageUrl` 조회는 별도 문제다. object 공개, 만료형 presigned URL, Backend proxy 또는 CDN 중 전달 정책을 정해야 한다.

### C.20 자동화 기능 — 현재 기준 반영
- API: `GET/PATCH /automation`, `GET /automation/logs`, `POST /automation/train`, `GET /automation/model`
- DB: `AutomationSetting`, `AutomationModel`, `AutomationLog`, `DeviceCommand`
- Enum: DecisionMode(RULE_BASED/LEARNING_BASED/HYBRID, 기본 HYBRID), ModelStatus(INSUFFICIENT_DATA/READY/FAILED)
- **설정 기본값(코드 확정)**: autoWater/Light/Optimize=false, wateringSafetyEnabled=false, decisionMode=HYBRID, minLearningDataCount=30, waterThresholdPercent=35.0, lightOnThresholdLux=300.0, lightOffThresholdLux=500.0, lightStartTime=08:00, lightEndTime=18:00
- 자동 급수: ESP 저장 후 → 설정/모델/effective 임계치 → 설정 기반 safety → cooldown/진행중 명령/활성 Pi·펌프 검증 → WATER 생성 or skip 로그. 일반 임계치가 safety보다 먼저라 전용 safety 의미는 조합에 따라 달라짐
- 자동 조명: Pi 저장 후 → autoLightEnabled/시간범위/조도 임계치 → LIGHT_ON/OFF or skip
- 학습: 최근 14일 통계 → 추천 임계치(Double) + confidence(Double) + dataCount(Integer) + ModelStatus. autoOptimizeEnabled+confidence 충족 시 설정 자동 반영. 기본 상태 INSUFFICIENT_DATA, READY/FAILED는 factory 지정

### C.21 FCM 푸시 알림 — 미구현 확정
- `firebase_core`/`firebase_messaging` 의존성만 선언. 초기화/토큰 저장/수신 handler/Backend 발송 모두 없음. 사용자가 Apple 개발자 계정 부재로 미구현 확정

### C.22 배포 / 실제 기기 실행 — 운영 확정
- A.14 참조. Lightsail + Cloudflare + Nginx + Certbot, Backend는 `screen` 수동 실행, AI/Pi는 systemd, CI/CD 미사용

### C.23 발표자료 / 데모 시연 — I 섹션 참조
- 데모 가능: 가입/로그인, 식재/수확, 인벤토리, 출석, 도감, 센서 수집, IoT 조회, 수동 물주기/조명, AI 변환, MJPEG
- 계획/미구현: FCM(미구현), 팬(없음)
---

## D. API 최신 문서

> API_SPECIFICATION.md 기준. 모든 REST 응답은 `ApiResponse<T>`(`success`/`message`/`data`). 인증: 사용자 JWT(`Authorization: Bearer` 또는 `jwt_token` cookie), 장치 `X-DEVICE-KEY`. HTTP 상태: 400/401/403/405/409/500.

### D.0 공통
```json
// 성공
{ "success": true, "message": "...", "data": { } }
// 오류
{ "success": false, "message": "...", "data": null }
```

### 인증 / 사용자 / 홈 / 공개 마스터

| # | Method | URL | 인증 | Request | Response | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| D.1 | POST | `/api/auth/signup` | 공개 | `{email,password,nickname}` | `{userId,email,nickname,grantedItems[]}` | 반영 |
| D.2 | POST | `/api/auth/login` | 공개 | `{email,password}` | `{accessToken,user{userId,email,nickname,role}}` | 반영 |
| D.3 | POST | `/api/auth/oauth/kakao` | 공개 | `{code,redirectUri}` | D.2와 동일 | 반영 |
| D.4 | POST | `/api/auth/oauth/google` | 공개 | `{code,redirectUri}` | D.2와 동일 | 반영 |
| D.5 | GET | `/api/users/me` | JWT | - | `{userId,email,nickname,role,createdAt}` | 반영 |
| D.6 | PATCH | `/api/users/me` | JWT | `{nickname}` (≤50) | `{userId,nickname}` | 반영 |
| D.6a | PATCH | `/api/users/me/password` | JWT | `{currentPassword,newPassword}` | LOCAL만, currentPassword 검증, tokenVersion 증가 | 반영 |
| D.6b | DELETE | `/api/users/me` | JWT | - | soft delete, tokenVersion 증가 | 반영 |
| D.6c | POST | `/api/users/me/logout` | JWT | - | 서버측 로그아웃, tokenVersion 증가 | 반영 |
| D.7 | GET | `/api/home` | JWT | - | `{user, mainUserPlant}` | 반영 |
| D.8 | GET | `/api/plants` | 공개 | - | `[{plantId,name,category,imageUrl}]` | 반영 |
| D.9 | GET | `/api/plants/{plantId}` | 공개 | path | +`description,growthDays` | 반영 |
| D.10 | GET | `/api/items?itemType=` | 공개 | query | `[{itemId,name,itemType,imageUrl}]` | 반영 |
| D.11 | GET | `/api/items/{itemId}` | 공개 | path | +`description,linkedPlantId` | 반영 |
| D.12 | GET | `/api/quests?questType=` | 공개 | query | 목표/반복/활성 | 반영 |
| D.13 | GET | `/api/quests/{questId}` | 공개 | path | +보상/수량 | 반영 |

D.1 검증: email 형식, password ≥4자, nickname ≤50자. 기본 SEED/POT 마스터 미생성 시 409.
D.3/D.4 주의: OAuth DTO validation 없음. client 설정은 JAR 내부 application-keys.yaml(운영 동작 확인).

### 사용자 육성

| # | Method | URL | 인증 | Request | 비고 | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| D.14 | POST | `/api/user-plants` | JWT | `{userItemId,nickname?}` | OWNED SEED+연결 Plant 필요, SEED→USED. GROW_PLANT는 수확 시점 진행 | 반영 |
| D.15 | GET | `/api/user-plants?status=` | JWT | query | 조회 시 HARVESTABLE 자동 갱신 | 반영 |
| D.16 | GET | `/api/user-plants/{id}` | JWT | path | +equippedPot | 반영 |
| D.17 | PATCH | `/api/user-plants/{id}` | JWT | `{nickname}` (≤50) | 별명 수정 | 반영 |
| D.18 | POST | `/api/user-plants/{id}/harvest` | JWT | - | HARVEST/GROW_PLANT 퀘스트 진행 증가 | 반영 |
| D.19 | GET | `/api/user-items?itemType=&status=` | JWT | query | 마스터별 그룹화 | 반영 |
| D.20 | POST | `/api/user-items/{id}/equip-pot` | JWT | `{userPlantId}` | OWNED POT만, 기존 EQUIPPED 자동 해제 | 반영 |
| D.21 | POST | `/api/user-items/{id}/unequip-pot` | JWT | - | EQUIPPED POT만 | 반영 |
| D.22 | POST | `/api/user-items/{id}/use-nutrient` | JWT | `{userPlantId}` | USED+식물 연결만, 성장 효과 없음 | 반영 |
| D.23 | GET | `/api/user-quests?questType=&status=` | JWT | query | 현재 기간 자동 생성 | 반영 |
| D.24 | GET | `/api/user-quests/{id}` | JWT | path | 보상 포함 상세 | 반영 |
| D.25 | POST | `/api/user-quests/{id}/reward` | JWT | - | ACHIEVABLE만 보상 | 반영 |
| D.26 | POST | `/api/attends/today` | JWT | - | `{attendId,attendDate,streakCount}`, ATTEND 진행 | 반영 |
| D.27 | GET | `/api/attends?year=&month=` | JWT | query | 둘 다/둘 다 생략, 한쪽만 400 | 반영 |
| D.28 | GET | `/api/collections` | JWT | - | plant별 collected/harvestCount | 반영 |
| D.29 | GET | `/api/collections/{plantId}` | JWT | path | +harvestedPlants[] | 반영 |

### 앱 IoT / 자동화

| # | Method | URL | 인증 | 비고 | 상태 |
| --- | --- | --- | --- | --- | --- |
| D.30 | GET | `/api/user-plants/{id}/iot/latest` | JWT | growSpace/environment/soil/latestImage{aiImageUrl} | 반영 |
| D.31 | GET | `/api/user-plants/{id}/iot/images` | JWT | PlantImageDto[] | 반영 |
| D.32 | POST | `/api/user-plants/{id}/iot/water` | JWT | 활성 펌프·Pi + 진행중 WATER 없음 → PENDING. `createWaterCommand()`가 durationSeconds=1 생성 | 반영 |
| D.33 | POST | `/api/user-plants/{id}/iot/light/on` | JWT | 활성 Pi + 진행중 조명 없음. duration=null | 반영 |
| D.34 | POST | `/api/user-plants/{id}/iot/light/off` | JWT | 위와 동일 | 반영 |
| D.35 | POST | `/api/user-plants/{id}/iot/refresh` | JWT | SENSOR_REFRESH PENDING 생성, 진행 중이면 409 | 반영 |
| D.36 | GET | `/api/user-plants/{id}/automation` | JWT | SettingResDto(기본 생성) | 반영 |
| D.37 | PATCH | `/api/user-plants/{id}/automation` | JWT | null 필드 기존 유지. wateringSafetyEnabled 저장 | 반영 |
| D.38 | GET | `/api/user-plants/{id}/automation/logs` | JWT | 최근 30개 | 반영 |
| D.39 | POST | `/api/user-plants/{id}/automation/train` | JWT | 최근 14일 통계 모델 생성 | 반영 |
| D.39a | GET | `/api/user-plants/{id}/automation/model` | JWT | 최신 모델, 없으면 오류 | 반영 |

D.36 자동화 설정 검증: minLearningDataCount≥1, waterThresholdPercent 0~100, cooldown≥0, lux≥0(OFF>ON 동시 전달 시), time 형식 binding.

### 장치 수집 / 명령

| # | Method | URL | 인증 | Request | 비고 | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| D.40 | POST | `/api/iot/raspberry/environment` | X-DEVICE-KEY | `{temperature,humidity,light,measuredAt}` (nullable) | RASPBERRY_PI+공간 필요. 자동 조명 평가 | 반영 |
| D.41 | POST | `/api/iot/esp/soil-moisture` | X-DEVICE-KEY | `{soilMoistureRaw,soilMoisturePercent,measuredAt?}` | ESP32+식물 필요. 자동 급수 평가 | 반영 |
| D.42 | POST | `/api/iot/plant-images` | X-DEVICE-KEY | multipart `file`,`userPlantId?`,`capturedAt?` | jpg/jpeg/png/webp와 대응 MIME, ≤20MiB. 응답 plantImageId 등 | 반영 |
| D.43 | GET | `/api/iot/commands/pending` | X-DEVICE-KEY | - | PENDING 오름차순, commandType/durationSeconds/pumpChannel | 반영 |
| D.44 | PATCH | `/api/iot/commands/{id}/processing` | X-DEVICE-KEY | - | PENDING→PROCESSING | 반영 |
| D.45 | PATCH | `/api/iot/commands/{id}/complete` | X-DEVICE-KEY | `{success,resultMessage?}` | PROCESSING→SUCCESS/FAILED | 반영 |

### IoT 구성 / AI / 관리자

| # | Method | URL | 인증 | 비고 | 상태 |
| --- | --- | --- | --- | --- | --- |
| D.46 | POST | `/api/iot/grow-spaces` | JWT | `{name,description?}`, 이름 중복 불가 | 반영(권한 주의) |
| D.47 | GET | `/api/iot/grow-spaces` | JWT | 사용자 범위 제한 미확인 | 반영 |
| D.48 | POST | `/api/iot/grow-spaces/{id}/plants` | JWT | `{userPlantId}`, 중복 연결 불가 | 반영 |
| D.49 | GET | `/api/iot/grow-spaces/{id}/plants` | JWT | 공간 내 식물 | 반영 |
| D.50 | POST | `/api/iot/devices` | JWT | `{deviceName,deviceType,deviceKey,growSpaceId?,userPlantId?}`. Pi=공간필수/식물불가, ESP=식물필수 | 반영 |
| D.51 | GET | `/api/iot/devices` | JWT | 전체 반환, deviceKey 응답 제외 | 반영 |
| D.52 | POST | `/api/iot/pump-channels` | JWT | 공간/식물/Pi + channelName + GPIO/relay. 식물당 1개 | 반영 |
| D.53 | GET | `/api/iot/pump-channels` | JWT | 전체 | 반영 |
| D.54 | POST | `/api/ai/plant-images/{id}/result` | X-AI-Worker-Secret | `{finalAiUrl}`. 원본 PlantImage+UserPlant 연결 필요 | 반영 |
| D.55a | POST | `/api/admin/plants` | ADMIN | CreatePlantReqDto | 반영 |
| D.55b | POST | `/api/admin/items` | ADMIN | CreateItemReqDto (SEED 연결식물 필수) | 반영 |
| D.55c | POST | `/api/admin/quests` | ADMIN | CreateQuestReqDto | 반영 |

### 관리자 Web (Thymeleaf)
`GET /admin/login`(화면; POST 처리는 별도 없음 — 대신 `/api/auth/login` AJAX + `jwt_token` cookie), `GET /admin`·`/admin/index`, `GET /admin/users`·`/{id}`, `POST /admin/users/{id}/toggle-role`, `POST /admin/users/{id}/delete`(soft delete), `GET/POST /admin/plants(/new)`·`/items(/new)`·`/quests(/new)`·`/iot(/new)`.
→ GAP-06: form login 비활성이나 JWT cookie 인증은 동작(부분 구현). JwtAuthenticationFilter가 cookie 읽음.

### AI Worker (FastAPI)
| # | Method | URL | 인증 | Request | Response | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| D.57 | GET | `/health` | 없음 | - | `{success,message}` | 반영 |
| D.58 | POST | `/process` | 없음(위험) | `{plantImageId,userPlantId?,imageUrl,name?}`. name은 1~100자 문자·숫자·`_`·`-`; imageUrl은 configured S3 virtual-host/prefix만 처리 | `{...,status:"PROCESSING"}` (접수만) | 작업명·S3 URL/key 제한 반영, endpoint 인증 잔여 |

> `/process` 응답의 `PROCESSING`은 접수 의미일 뿐, Backend `AiImageStatus` enum(`SUCCESS`/`FAILED`)이 아님.

### Pi Stream Server (0.0.0.0:8000)
`GET /`(HTML), `GET /health`(JSON), `GET /stream.mjpg`, `GET /stream/sunflower.mjpg`, `GET /stream/basil.mjpg`. 인증 없음. `/snapshot.jpg` legacy 진입점은 제거됨(GAP-07 해소).

### Sensor Refresh
- `POST /api/user-plants/{id}/iot/refresh` → Backend endpoint와 `CommandType.SENSOR_REFRESH` 명령 생성 경로 구현 완료(GAP-01/02 해소).

### Flutter ↔ Backend 계약 대조 (API_SPEC 10)
| Flutter | Backend | 판정 |
| --- | --- | --- |
| 인증/홈/식물/아이템/컬렉션/퀘스트/출석 | 대응 Controller | 연결 가능 |
| IoT latest/water/light | 대응 Controller | 연결 가능 |
| 자동화 get/patch/train/model/logs | 대응 Controller | 연결 가능 |
| `/iot/refresh` POST | endpoint + SENSOR_REFRESH 명령 생성 구현 | 일치 |
| `wateringSafetyEnabled` | DTO/Entity와 수동 급수 반영; 자동 safety는 조건 의미 정리 필요 | 부분 일치 |
| `/users/me` | 구현 있음 | 화면 사용 여부 별도 확인 |
---

## E. DB 최신 문서

> 실제 SQL DDL은 8개 문서 본문에 없고 JPA `ddl-auto: update`로 자동 생성. 컬럼은 BACKEND.md Entity 표 + API_SPEC DTO + GAP_DECISION_REVIEW 코드 확인 + 소스 확정값 기준.

### E.0 BaseEntity (공통)
- `createdAt`, `updatedAt`
- `deleted`(boolean), `delete()`, `restore()` — **코드 확정**. 단 일부 IoT/Automation 엔티티는 BaseEntity 대신 자체 `deleted` 필드 보유(상속 비통일)

### E.1 User
| 컬럼 | 타입 | Null | 설명 |
| --- | --- | --- | --- |
| id(userId) | bigint | NO | PK |
| email | varchar | NO | unique |
| password | varchar | NO | BCrypt |
| nickname | varchar | NO | ≤50 |
| role | enum | NO | USER/ADMIN |
| provider | varchar/enum | YES | OAuth 제공자 (**코드 확정**) |
| providerId | varchar | YES | 제공자 식별자 (**코드 확정**) |
| profileImageUrl | varchar | YES | 프로필 (**코드 확정**) |
| createdAt | datetime | NO | 가입 시각 |

관계: 1:N → UserPlant, UserItem, UserQuest, Attend, GrowSpace(소유)

### E.2 Plant(마스터)
plantId(PK), name(중복불가), category, imageUrl, description, growthDays

### E.3 Item(마스터)
itemId(PK), name, itemType(SEED/POT/NUTRIENT), imageUrl, description, linkedPlantId(SEED 필수)

### E.4 Quest(마스터)
questId(PK), questType, resetCycle, targetType(ATTEND/WATERING/GROW_PLANT/HARVEST), targetValue, rewardItemId, rewardCount, description, active
→ WATERING/GROW_PLANT 진행 호출 연결됨

### E.5 UserPlant
userPlantId(PK), userId(FK), plantId(FK), nickname(≤50), status(GROWING/HARVESTABLE/HARVESTED), plantedAt, expectedHarvestableAt, harvestedAt

### E.6 UserItem
userItemId(PK), userId(FK), itemId(FK), status(OWNED/EQUIPPED/USED), userPlantId(FK, POT/NUTRIENT 대상)

### E.7 UserQuest
userQuestId(PK), userId(FK), questId(FK), progress, status(IN_PROGRESS/ACHIEVABLE/COMPLETED/EXPIRED), periodStart, periodEnd, rewardClaimedAt

### E.8 Attend
attendId(PK), userId(FK), attendDate(유저-날짜 unique), streakCount

### E.9 GrowSpace
growSpaceId(PK), userId(FK, 소유), name(중복불가), description, active, createdAt

### E.10 GrowSpacePlant
growSpacePlantId(PK), growSpaceId(FK), userPlantId(FK, unique) — 1식물 1공간

### E.11 IotDevice
deviceId(PK), deviceName, deviceType(RASPBERRY_PI/ESP32), deviceKey(DB 저장/검증용, API 응답 제외), growSpaceId(Pi 필수), userPlantId(ESP 필수), active, lastSeenAt

### E.12 PumpChannel
pumpChannelId(PK), growSpaceId(FK), userPlantId(FK, 식물당1개), deviceId(FK,Pi), channelName, gpioPin, relayChannel, active

### E.13 RaspberrySensorData
sensorDataId(PK), growSpaceId(FK), deviceId(FK), temperature(double,Y), humidity(double,Y), light(double,Y), measuredAt(NO, null이면 서버시각)

### E.14 EspSensorData
sensorDataId(PK), userPlantId(FK), deviceId(FK), soilMoistureRaw(int,Y), soilMoisturePercent(double,Y), measuredAt(NO)

### E.15 PlantImage
plantImageId(PK), userPlantId(FK,Y), growSpaceId(FK), deviceId(FK), imageUrl(S3), originalFilename, capturedAt

### E.16 AiPlantImage
aiPlantImageId(PK), plantImageId(FK), userPlantId(FK), aiImageUrl(S3), status(**AiImageStatus: SUCCESS/FAILED만, 기본 SUCCESS**), createdAt
→ AI Worker 응답 `PROCESSING`은 DB enum 아님

### E.17 DeviceCommand
commandId(PK), userPlantId(FK), growSpaceId(FK), deviceId(FK), pumpChannelId(FK,Y), commandType(WATER/LIGHT_ON/LIGHT_OFF/SENSOR_REFRESH), commandStatus(PENDING/PROCESSING/SUCCESS/FAILED/CANCELLED), durationSeconds(**Integer, nullable; `createWaterCommand()`는 1, LIGHT/SENSOR_REFRESH는 null; DEFAULT/MAX_WATER_DURATION_SECONDS=1**), requestedAt, processingAt, completedAt, resultMessage
→ GAP-04 해소: Backend WATER 생성은 `0 < durationSeconds <= 1`을 강제하며 Pi도 실행 직전에 같은 상한을 검사

### E.18 AutomationSetting (기본값 코드 확정)
automationSettingId(PK), userPlantId(FK), autoWaterEnabled(false), autoLightEnabled(false), autoOptimizeEnabled(false), wateringSafetyEnabled(false), decisionMode(HYBRID), minLearningDataCount(30), waterThresholdPercent(35.0), waterCooldownMinutes(30*), lightOnThresholdLux(300.0), lightOffThresholdLux(500.0), lightStartTime(08:00), lightEndTime(18:00), lightCooldownMinutes(10*)
→ **`wateringSafetyEnabled` 필드와 수동 급수 반영**(GAP-03 부분 해소). 자동 safety 조건 순서·기준은 잔여
→ *cooldown 기본값은 API_SPEC 6.6 기준(이번 코드 확정 목록엔 미포함)

### E.19 AutomationModel (타입 코드 확정)
automationModelId(PK), userPlantId(FK), recommendedWaterThreshold(Double), recommendedLightOnThreshold(Double), recommendedLightOffThreshold(Double), soilDataCount(Integer), lightDataCount(Integer), waterCommandCount(Integer), dryRate(Double), recoveryAmount(Double), confidenceScore(Double), modelStatus(AutomationModelStatus, 기본 INSUFFICIENT_DATA, READY/FAILED는 factory 지정), learningPeriodStart, learningPeriodEnd, createdAt

### E.20 AutomationLog
automationLogId(PK), userPlantId(FK), automationType, triggerSensorType, triggerValue(double), thresholdValue(double), commandId(FK,Y; skip이면 null), message, createdAt

---

## F. 현재 기준 파일별 설명 문서

### F.1 Backend
- `GreenlinkApplication.java` — Spring Boot 시작점
- `application.yaml` — JPA(ddl-auto:update, SQL로그), multipart 20MB, JWT, `S3_BUCKET`/`AWS_REGION`, 선택 import `yaml/application-keys.yaml`. 마지막 운영 JAR에는 keys 파일이 포함됐으나 현재 S3 credential은 기본 provider chain을 사용하며 JWT/DB/OAuth 외부화가 필요
- `SecurityConfig.java` — 공개/JWT/장치/ADMIN 경로 정책. form login 비활성(GAP-06). 공개: auth, 마스터 조회, iot 장치경로, `/api/ai/**`
- `AiWorkerAuthInterceptor`+`WebMvcConfig` — `/api/ai/**` callback에 `X-AI-Worker-Secret` shared secret header 검증 적용
- `JwtAuthenticationFilter`/`JwtTokenProvider` — JWT 발급/검증. **Authorization 헤더 + `jwt_token` cookie 둘 다** 추출, tokenVersion claim과 DB 값 비교
- `AuthController`+`AuthService` — 가입(이메일 중복/BCrypt/기본 SEED+POT/업적 퀘스트)/로그인/OAuth
- `UserController`+`UserService` — 내 정보/닉네임, LOCAL 비밀번호 변경, soft delete 탈퇴, tokenVersion 서버 로그아웃
- `IotDeviceController`+`IotDeviceDataService` — 장치 키 검증, 센서/이미지 저장, lastSeenAt 갱신, 자동화 평가 호출
- `IotAppController`+`IotAppService` — 최신 IoT 조회, 수동 물/조명 명령 생성
- `IotCommandService` — 명령 조회/상태 전환
- `IotSetupController`+`IotSetupService` — 공간/장치/펌프 등록(권한 범위 주의, deviceKey는 응답 제외)
- `AutomationController`+`AutomationService`+`AutomationLearningService` — 설정/로그/학습/모델. 센서 저장 후 자동 판단(통계/규칙)
- `AiPlantImageController`+`AiPlantImageService` — AI 결과 URL 수신→AiPlantImage 저장(`X-AI-Worker-Secret` 검증 경로)
- `S3UploadService`+`S3Config` — 20MiB 및 jpg·jpeg·png·webp와 MIME의 정확한 대응 검증, S3 저장. 원본 key `greenlink/userplant/{storedFilename}`; SDK 기본 credential provider chain 사용
- `AdminController`+`AdminWebController` — REST 마스터 생성 + Thymeleaf. 로그인은 jwt_token cookie 방식

### F.2 Frontend
- `main.dart` — 시작/테마/Kakao SDK 초기화(앱 키 포함)
- `core/network/api_client.dart` — 공통 HTTP + JWT Bearer + 401 처리. token substring debug 로그 제거 완료
- `core/network/token_storage.dart` — shared_preferences 토큰
- `core/constants/api_paths.dart` — REST 경로. `/iot/refresh` 정의 및 Backend 연결 완료
- `core/constants/stream_urls.dart` — 카메라 스트림 주소(하드코딩)
- `core/constants/iot_thresholds.dart` — 토양 부족/과습 UI 상수(Backend와 별개)
- `core/config/camera_config.dart` — 식물별 스트림 매핑
- `services/auth_service.dart` — 가입/로그인/OAuth (Kakao redirect, Google client 설정 포함)
- `services/iot_service.dart` — 최신/수동제어. `/iot/refresh` 호출 및 409 처리
- `services/automation_service.dart` — 자동화. `wateringSafetyEnabled` 전송 및 Backend 반영
- `screens/splash_page.dart`, `main_page.dart`, `user_plant/user_plant_detail_page.dart`, `iot/iot_status_page.dart`(refresh 버튼 연결 완료), `widgets/mjpeg_stream_view.dart`(byte stream 파싱). 개발용 `widgets/debug_panel.dart`는 삭제됨

### F.3 ESP32 — `src/main.cpp`
- `setup()`: Serial/ADC(12bit,ADC_11db)/Wi-Fi/최초 전송. DEVICE_KEY를 Serial 출력(제거 필요)
- `loop()`: SEND_INTERVAL_MS(10분)마다 measureAndSend
- `readSoilRaw()`: GPIO34 10회 평균
- `convertRawToPercent(raw)`: DRY_RAW/WET_RAW 선형 변환(0~100), DRY==WET면 0 반환, 범위 밖 경고
- `createJsonBody`, `sendSoilMoistureData`(HTTPClient, X-DEVICE-KEY, timeout 5000), `measureAndSend`, `connectWiFi`(60회 후 restart), `ensureWiFiConnected`

### F.4 Raspberry Pi
- `config.py` — BASE_URL/DEVICE_KEY/AI_WORKER_URL(하드코딩), GPIO/센서/crop/식물별 userPlantId 상수, 센서 600초, polling 3초, crop(해바라기 우/바질 좌), 출력 1080x1620
- `sensor_service.py` — `read_all_sensors()` DHT22 재시도 + BH1750
- `sensor_uploader.py` — `upload_sensor_data_safe()` → POST environment(X-DEVICE-KEY)
- `sensor_main.py` — 1회 측정/업로드
- `api_client.py` — pending GET, processing/complete PATCH
- `relay_control.py` — LED27/펌프22·23 active-low, 펌프 duration 후 finally off, `all_off()`
- `water_duration.py` — WATER duration은 key 누락 시에만 1초. 그 외에는 유한한 숫자이면서 `0 < duration <= 1`만 허용
- `command_worker.py` — `CommandWorker.run_forever()` 3초 polling. WATER는 relay 호출 전 duration을 검사하며 invalid 값이면 펌프를 켜지 않고 FAILED 보고 후 `all_off()`. light/sensor_refresh 분기 포함
- `stream_server.py` — Flask+Picamera2 MJPEG(0.0.0.0:8000), 180도 회전, route 5개
- `stream_snapshot_service.py` — MJPEG→JPEG 추출+crop
- `camera_main.py` — active 진입점, /stream.mjpg 프레임 추출(회전 없음). **CLI 인자 없음(--plant 미지원)**
- `camera_service.py` — Picamera2 직접 still(대안)
- `uploader.py` — multipart 업로드 후 ai_trigger
- `ai_trigger.py` — POST {AI_WORKER_URL}/process `{plantImageId,userPlantId,imageUrl,name}`
- `run_sensor.sh`(cron 10분)/`run_camera.sh`(cron 09·21시)/`run_command.sh`
- systemd: `greenlink-command.service`(command_worker), `greenlink-stream.service`(stream_server), Restart=always/5s, 사용자 greenlink, 경로 /home/greenlink/greenlink

### F.5 Ubuntu AI Worker
- `ai_worker_api.py` — FastAPI /health /process, BackgroundTasks. ProcessRequest(plantImageId,userPlantId,imageUrl,name) → run_ai_job → process_one
- `job_name.py` — 작업 이름 1~100자 및 문자·숫자·밑줄·하이픈 제한. API와 `process_one`에서 이중 검증
- `process_one.py` — `download_image()`이 `s3_client.download_source_image_from_s3(imageUrl)`을 호출→remove_pot→openai_transform→S3 PUT→`save_ai_result_to_backend`. CLI(--url --name --plant-image-id)
- `remove_pot.py` — **MODEL_NAME="u2netp", ALPHA_THRESHOLD=12, FALLBACK_TRIM_RATIO=0.24, BOTTOM_PAD_PX=28**
- `openai_transform.py` — **client.images.edit(model="gpt-image-1.5", image=[전처리,style], prompt=PROMPT, input_fidelity="high")**. background/output_format 없음. prompt: 형태 보존/스타일 색감·질감 참고/화분·배경 생성 금지
- `s3_client.py` — boto3 GET/PUT. 원본은 configured bucket/region의 정확한 HTTPS virtual-host URL과 `greenlink/userplant/{단일 파일}`만 허용하고 확장자·MIME·20MiB 선언/실제 stream 길이를 검증. 결과 key는 `greenlink/ai/userplant/{원본stem}.png`
- `style_plant.png` — 스타일 참조
- 삭제 완료: `ai_background_remove.py`, `alpha_composite.py`, `compose_pot.py`, `pot_base.png`
---

## G. 설정값 최신 기준

> 운영값(도메인/IP/host/key/secret/bucket)은 노출하지 않음. 구조/형태만 정리.

### G.1 서버 / 배포 (운영 확정)
- 인프라: **AWS Lightsail Ubuntu**
- 요청 흐름: 사용자 → Cloudflare → Nginx(443, Certbot HTTPS, 80→443 redirect) → Spring Boot `127.0.0.1:8080`
- Backend 실행: 마지막 운영 확인 기준 `screen` 세션의 수동 `java -jar`; Backend systemd unit 없음
- AI Worker: `greenlink-ai.service` systemd, `uvicorn ... --host 0.0.0.0 --port 9000`
- Pi: `greenlink-command.service`, `greenlink-stream.service`(enabled/running, Restart=always/5s) + cron
- CI/CD: 미사용(로컬 Gradle build → JAR 수동 전송 → `screen`에서 수동 실행)
- Nginx site: `/etc/nginx/sites-available(enabled)/greenlink`, 443 SSL server block, `location /` → 127.0.0.1:8080
- Certbot: fullchain.pem/privkey.pem. 자동갱신 timer/cron 상태는 **추가 확인 필요**
- Cloudflare: 서버 도메인 + 카메라 도메인. cloudflared는 Lightsail 미실행 / Pi 실행(127.0.0.1:20241)

### G.2 DB
- 종류: MySQL, JPA `ddl-auto: update`, SQL 로그 활성
- 이름/계정/비번: 운영 외부 파일 없음. 배포 JAR 내부 `BOOT-INF/classes/yaml/application-keys.yaml`에 DB password 포함(값 미노출)

### G.3 S3 / 이미지
- 원본 key: `greenlink/userplant/{storedFilename}`
- storedFilename: `user-plant-{userPlantId}-{yyyyMMdd-HHmmss}-{uuid8}.{ext}` 또는 `grow-space-{ts}-{uuid8}.{ext}`
- AI 결과 key: `greenlink/ai/userplant/{원본파일stem}.png`
- Backend credential: AWS SDK 기본 credential provider chain. 현재 소스는 `aws.access-key`/`aws.secret-key` property를 읽지 않음
- AI Worker credential: boto3 기본 credential provider chain(환경 변수 access/secret/session token, 공유 profile, instance role 등). 코드에 credential을 직접 전달하지 않음
- AI Worker 원본 읽기: configured bucket/region의 정확한 HTTPS virtual-host URL에서 `greenlink/userplant/{단일 파일}`만 boto3 `get_object`로 읽음. userinfo/query/fragment, 443 외 포트, 다른 host, prefix 이탈, 중첩·인코딩 경로 우회를 거부
- 허용: 원본 확장자 jpg/jpeg/png/webp, 대응 ContentType, 선언·실제 크기 모두 0 초과 20MiB 이하. 결과는 PNG
- 동작 상태: 과거 업로드/S3 저장/MySQL 메타 저장/앱 조회 성공 기록과 코드/mock 검증은 있으나, 이번 확인에서는 configured bucket이 없어 Worker `get_object` live smoke를 수행하지 못함
- private bucket 주의: Worker SDK 권한과 Flutter 이미지 조회 권한은 별개다. Flutter가 naked URL을 사용하므로 public object, presigned URL, Backend proxy 또는 CDN 정책이 필요

### G.4 IoT / Pi / ESP32
- Pi systemd: command(command_worker.py)/stream(stream_server.py), enabled/running, Restart=always/5s
- Pi cron: 센서 `run_sensor.sh` 10분(sensor_main.py), 카메라 `run_camera.sh` 매일 09·21시(camera_main.py)
- Pi 로그: command.log/command_error.log/stream.log/stream_error.log/sensor.log/camera.log
- stream port: 0.0.0.0:8000 / command polling 3초 / 센서 600초
- GPIO: LED 27, 바질 펌프 22, 해바라기 펌프 23, Active LOW, DHT 4, BH1750 bus1/0x23
- crop: 해바라기 우/바질 좌, 출력 1080x1620, stream 180도 회전(camera_main 회전 없음)
- Pi → Backend 8080 직접, Pi → AI 9000 직접
- ESP: GPIO34 ADC, 10분 주기, POST soil-moisture, 펌프 제어 없음
- root crontab 없음

### G.5 Ubuntu GreenLink AI
- 실행: greenlink-ai.service, uvicorn 0.0.0.0:9000(HTTP)
- 모델: `gpt-image-1.5` images.edit
- 호출 인자: image=[전처리,style], prompt=PROMPT, input_fidelity="high". **background/output_format 없음**
- 전처리(remove_pot): u2netp / ALPHA_THRESHOLD=12 / FALLBACK_TRIM_RATIO=0.24 / BOTTOM_PAD_PX=28
- 결과 key: greenlink/ai/userplant/{원본stem}.png
- 작업명: `job_name.py`에서 1~100자 문자·숫자·밑줄·하이픈만 허용하며 API와 처리 직전에 이중 검증
- 원본 다운로드: exact configured S3 URL/prefix만 boto3 `get_object`로 읽고 URL·key·확장자·MIME·20MiB 선언/stream 길이를 fail-close 검증
- 9000 포트 외부 공개 → 제한 필요

### G.6 AI Worker S3 읽기 권한 결정

현재 코드는 원본을 boto3 `get_object`로 직접 읽으므로 Worker 실행 identity에 `s3:GetObject`가 필요하다. boto3 client는 명시적 key 없이 기본 credential provider chain을 사용한다. 따라서 환경 변수, 공유 profile, instance role 중 실제 systemd 서비스가 선택한 identity에 다음처럼 원본 prefix로 제한한 권한을 부여할 수 있다.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::<bucket>/greenlink/userplant/*"
  }]
}
```

이 권한만으로 bucket 목록 전체를 열 필요는 없다. 위 예시는 원본 읽기 권한만 나타내며, AI 결과 업로드의 `s3:PutObject` 권한은 결과 prefix에 별도로 필요하다. 사용자 관리형 KMS key로 object를 암호화했다면 해당 key의 `kms:Decrypt` 권한과 key policy 허용도 필요하다. bucket policy 또는 명시적 Deny가 identity policy의 Allow보다 우선할 수 있으므로 IAM policy 문서만 보고 실제 사용 가능하다고 단정할 수 없다.

코드와 mock 단위 검증은 완료됐지만 이번 확인 환경에는 configured bucket이 없어 실제 권한은 미검증이다. bucket 재생성 후 Worker systemd 서비스와 동일한 OS 사용자·환경 변수·credential chain, 동일한 `S3_BUCKET`/`AWS_REGION`에서 반드시 존재한다고 아는 `greenlink/userplant/` object로 확인한다. 다른 bucket·region이나 로그인 shell profile의 성공은 실제 Worker 권한을 증명하지 못한다.

```bash
aws sts get-caller-identity
aws s3api head-object \
  --bucket "$S3_BUCKET" \
  --key "greenlink/userplant/<known-existing-object>" \
  --region "$AWS_REGION"
aws s3api get-object \
  --bucket "$S3_BUCKET" \
  --key "greenlink/userplant/<known-existing-object>" \
  --region "$AWS_REGION" \
  /tmp/greenlink-known-object
```

마지막으로 같은 object URL로 Worker 전체 smoke를 실행해 URL/MIME/크기 검증까지 확인해야 한다. 알려진 object가 아니면 403/404 해석이 모호하다. IAM policy simulator는 보조 점검이며 실제 서비스 identity의 요청을 최종 기준으로 삼는다.

S3 bucket을 private로 유지해도 위 SDK 읽기는 가능하다. 그러나 Backend가 반환한 naked `imageUrl`/`aiImageUrl`을 Flutter가 직접 읽는 현재 구조에는 별도 전달 정책이 필요하다. object 공개, 짧은 만료의 presigned URL, Backend proxy, CDN 중 하나를 정해야 하며 Worker의 `s3:GetObject` 허용만으로 앱 이미지가 보이는 것은 아니다.

---

## H. 오류와 해결 과정 최신 정리

| # | 상황 | 유효성 | 원인/해결 | 근거 |
| --- | --- | --- | --- | --- |
| H.1 | AI에 alpha mask 합성 시 잘림 | 해결 완료 | AI 결과와 원본 형상 불일치 → alpha 합성 폐기, 전처리 투명화로 전환 | UBUNTU_GREENLINK_AI |
| H.2 | AI 결과에 rembg 재적용 시 손상 | 해결 완료 | rembg는 전처리에서만 사용 | UBUNTU_GREENLINK_AI |
| H.3 | `compose_pot.py` SyntaxError | 해소 | legacy 파일 삭제 완료 | UBUNTU_GREENLINK_AI |
| H.4 | `/snapshot.jpg` 404 | 해소(GAP-07) | `camera_snapshot_main.py` legacy 파일 삭제 완료 | PI.md |
| H.5 | 센서 새로고침 404 | 해소(GAP-01/02) | Backend endpoint/enum/명령 생성 경로 구현 | FUNCTIONAL_SPEC |
| H.6 | 안전 toggle 반영 | 부분 해소(GAP-03) | Backend 필드·수동 차단 반영, 자동 safety는 이중 임계치/조건 순서 정리 필요 | FUNCTIONAL_SPEC |
| H.7 | 급수 duration | 해소(GAP-04) | Backend/Pi 최대 1초 fail-close. key 누락만 1초 fallback, invalid 값은 펌프 미호출·FAILED. 물리 유량 교정은 별도 잔여 | FUNCTIONAL_SPEC, PI |
| H.8 | 관리자 로그인 | 부분 정정 | form login 없으나 jwt_token cookie 인증 동작 → cookie 보안 보강 | GAP_REVIEW §3 |
| H.9 | ESP 접촉불량 raw | 현재도 유효 | 경고 로그만 `[WARN] raw가 ...` → calibration 검증 | ESP.md |
| H.10 | Wi-Fi 실패 재시작 | 정상 동작 | 60회 후 `ESP.restart()` | ESP.md |
| H.11 | AI BackgroundTask 실패 추적 불가 | 현재도 유효 | print만, 실패 callback 없음 → 영속화 필요 | UBUNTU_GREENLINK_AI |
| H.12 | JWT secret 노출 | 현재도 유효 | 현재 `application.yaml`의 고정값이 JAR에 포함됨 → 외부화 | GAP_REVIEW §13.4 |
| H.13 | 장치 키 응답 노출 | 해소 | DeviceResDto/PumpChannelResDto에서 제거 | API_SPEC 6.8 |
| H.14 | AI callback 공개 | 해소 | `AiWorkerAuthInterceptor`가 `X-AI-Worker-Secret` 검증 | API_SPEC 3.5 |
| H.15 | 과거 배포 JAR 내부 secret 포함 | 재배포 시 확인 필요 | 마지막 운영 확인에는 DB/AWS/OAuth secret이 동봉됨. 현재 S3 코드는 기본 credential chain으로 전환됐으므로 legacy AWS key 제거와 DB/OAuth 외부화를 새 JAR에서 확인 | GAP_REVIEW §13.4 |
| H.16 | Lightsail 방화벽 공개 | 현재도 유효 | 3306/8080/9000 Any IPv4 → 제한(단 Pi 직접호출 고려) | GAP_REVIEW §13.6 |
| H.17 | Backend 자동복구 부재 | 미해소 | 마지막 운영 확인은 `screen` 수동 실행이며 Backend systemd unit 없음 | GAP_REVIEW §13.3 |
| H.18 | 관리자 cookie 보안 | 일부 해소 | `jwt_token` cookie에 Secure; SameSite=Strict 추가 완료. HttpOnly/CSRF 정책은 별도 검토 | GAP_REVIEW §3 |
| H.19 | AI 원본 URL의 SSRF/과대 응답 | 코드 해소 | exact S3 URL/prefix + boto3 GET + MIME/확장자/20MiB 선언·실제 stream fail-close 검증 | UBUNTU_GREENLINK_AI |
| H.20 | Worker S3 live 권한 | 확인 필요 | configured bucket 부재로 미검증. bucket 재생성 후 동일 서비스 identity·bucket·region·known object smoke 필요 | UBUNTU_GREENLINK_AI |

---

## I. 최종 판넬 / 발표 / 보고서 검토

### I.1~I.2 필요성/문제정의, 기존 비교
- 일치. 수정 불필요. "지속적 돌봄 연결", "V2R 기반 차별점" 유지 가능

### I.3 Key Technologies
| 판넬 | 검증 | 판정 |
| --- | --- | --- |
| Frontend Flutter / Backend Spring Boot / DB MySQL | 일치 | 유지 |
| IoT Device: Raspberry Pi | ESP32 미표기 | **"Raspberry Pi + ESP32" 보강 권장** |
| AI/Image Python(OpenAI) | gpt-image-1.5 + rembg | 유지 |
| Deployment Nginx + AWS | Lightsail+Cloudflare+Nginx+Certbot 운영 확인 | **대체로 정확**(Backend/AI/Pi systemd 구분 권장) |

### I.4~I.6 System Design
- 제어 흐름 `Flutter→Spring Boot→Pi→Relay→Pump/LED`: 일치(폴링 방식 명시 권장)
- 센서 흐름 `Sensors→Spring Boot→MySQL→Flutter`: 일치(ESP/Pi 분리 표기 권장)
- 이미지/AI 흐름 `RPI Camera→Server→OpenAI→S3→Flutter`: **"Server"가 Ubuntu AI Worker(별도 서버, gpt-image-1.5)임을 명확화. 투명화는 전처리 단계** → 수정 권장

### I.7 Specifications
- 대부분 일치(식물 등록/출석·퀘스트·아이템/센서/보정값 수분%/물주기·펌프/LED/RPI 카메라/OpenAI 변환/서버·DB)
- **"Nginx + HTTPS 서버 배포": 운영 사용 확정 → 판넬 표현 유지 가능** (이전 "수정 필요" 판정 철회)

### I.8 Implementations (데모 vs 계획 구분)
- 데모 가능: 가입/로그인, 식재/수확, 인벤토리, 출석, 도감, 센서 수집, IoT 조회, 수동 물주기/조명, AI 변환(외부 API 키 필요), MJPEG
- 계획/미구현/GAP: FCM(미구현), 팬(없음), GAP-06 보안 정책 정리

### I.9 Evaluation
- 유지: 구현 완성도/동작 확인/개선 필요(센서 보정·네트워크·장기 데이터)
- 보강: GAP-06 보안 정책 및 운영 잔여 확인 항목 반영 권장

### I.10 판넬 수정 우선순위 (정정 후)
| 우선순위 | 위치 | 수정 방향 |
| --- | --- | --- |
| 중간 | System Design 이미지/AI 흐름 | "Server"=Ubuntu AI Worker 명확화, 투명화=전처리 |
| 낮음 | Key Technologies IoT | "Raspberry Pi + ESP32" 추가 |
| 낮음 | 제어 흐름 | DeviceCommand 폴링 명시 |
| 낮음 | Evaluation | GAP 반영 |
| (철회) | "Nginx + HTTPS 배포" | 운영 확정으로 수정 불필요 |

---

## J. Codex / Antigravity / 개발 프롬프트 최신 정리

> 8개 문서에 프롬프트 자체는 없음. 8개 문서 + GAP_REVIEW 사실 기반으로 재구성. 기능 설명용 / 신규 추가용 구분.

### J.1 [기능설명] AI Worker 흐름
```text
AI Worker 활성 파이프라인(변경 금지):
1. POST /process → Pydantic 검증 → BackgroundTask → 즉시 PROCESSING
2. process_one: exact configured S3 URL/key 검증 → boto3 get_object(MIME/확장자/20MiB 선언·stream 길이 검증) → remove_pot(rembg u2netp + ALPHA_THRESHOLD=12 + FALLBACK_TRIM_RATIO=0.24 하단 24% 투명화 + BOTTOM_PAD_PX=28)
3. openai_transform: client.images.edit(model="gpt-image-1.5", image=[전처리,style_plant.png], prompt=PROMPT, input_fidelity="high")  # background/output_format 없음
4. s3_client: 최종 PNG PUT → greenlink/ai/userplant/{원본stem}.png
5. POST /api/ai/plant-images/{id}/result {"finalAiUrl":...}
금지: alpha_composite/compose_pot/pot_base 합성, AI 결과 rembg 재적용, OpenAI에 투명 파라미터 추가
legacy alpha_composite/compose_pot/pot_base/ai_background_remove 파일은 삭제 완료.
```

### J.2 [기능설명] Pi 카메라 흐름
```text
active 진입점은 camera_main.py(MJPEG /stream.mjpg 프레임 추출, config 고정 crop). --plant 인자 없음.
camera_snapshot_main.py legacy 파일은 삭제 완료(GAP-07 해소).
업로드: POST /api/iot/plant-images(X-DEVICE-KEY, multipart) → 응답 plantImageId/userPlantId/imageUrl → ai_trigger.
```

### J.3 [기능설명] Backend IoT+자동화
```text
ESP soil-moisture / Pi environment 저장 후 AutomationService 평가(통계/규칙).
조건 충족 시 DeviceCommand(PENDING) + AutomationLog. Pi가 pending GET→processing PATCH→GPIO→complete PATCH.
WATER duration은 Backend와 Pi가 `0 < durationSeconds <= 1`로 이중 제한. Pi는 key 누락 시에만 1초를 사용하며 invalid 값은 GPIO 호출 없이 FAILED. LIGHT는 null.
```

### J.4 [기능설명] Flutter↔Backend GAP
```text
GAP-01 /iot/refresh endpoint 구현 / GAP-02 SENSOR_REFRESH enum·명령 생성 구현 /
GAP-03 wateringSafetyEnabled 설정·수동 급수 반영(자동 safety 조건은 잔여) / GAP-04 Backend·Pi 최대 1초 fail-close 상한 구현 /
GAP-05 WATERING·GROW_PLANT 진행 연결 / GAP-06 form login 없음(jwt_token cookie 동작, Secure/SameSite 보강) /
GAP-07 camera_snapshot_main.py 삭제 완료
```

### J.5 [신규] FCM 푸시 — 미구현, 신규 구현용
```text
현재: 의존성만, 초기화/토큰/수신/발송 없음(미구현 확정).
추가 시: Flutter FirebaseMessaging 초기화+토큰 등록 service, Backend User.fcmToken + 송신 service + trigger 정책.
```

### J.6 [완료] 센서 refresh — GAP-01/02 해소
```text
Backend: CommandType.SENSOR_REFRESH 추가 + POST /iot/refresh endpoint + Service(소유/공간/Pi 검증, 진행중 없으면 PENDING 생성).
Pi 분기는 이미 존재. 자동화 비대상.
```

### J.7 [부분 완료] wateringSafetyEnabled — GAP-03
```text
AutomationSetting Entity + DTO에 boolean 추가. IotAppService의 수동 급수 400 차단은 동작.
AutomationService는 일반 effective water threshold를 먼저 검사하고 설정값 기반 safety threshold를 나중에 검사한다.
effective 기준 E, 설정 기준 S일 때 E >= S+10이고 센서값이 [S+10,E]인 경우에만 safety 전용 분기가 도달한다.
기본/RULE_BASED에서는 사실상 도달하지 않고 autoOptimize가 E를 S에 반영하면 다시 도달하지 않으므로 조건 의미와 순서를 통일해야 한다.
```

### J.8 [완료] 급수 duration 소프트웨어 상한 — GAP-04
```text
현재 허용 최대 작동 시간은 1초다.
Backend DeviceCommand는 WATER 생성 시 null·0 이하·1초 초과를 거부한다.
Pi는 durationSeconds key가 없을 때만 1초를 사용한다.
key가 있으면 bool을 제외한 유한한 숫자이고 0 < duration <= 1인 경우만 허용한다.
null·문자열·bool·NaN/무한대·0 이하·1초 초과는 펌프를 호출하지 않고 command를 FAILED로 보고한 뒤 all_off를 호출한다.

다만 1초는 유량 교정 전 fail-close 제한이며 물리적 안전 보증값은 아니다.
유량 q=측정ml/측정초,
상한=floor(안전급수ml × 0.7~0.8 / q).
동일 호스·높이에서 펌프별 10초 토출량과 화분의 안전 급수량·배수를 측정하고 20~30% 여유를 둔다.
교정 전에는 현재 Backend/Pi 1초 상한을 유지한다. 3초는 현재 코드가 거부하며 실측 전 안전값으로 사용하지 않는다.
상한 변경 시 Backend와 Pi를 함께 바꾸고 회귀 테스트와 실제 화분 시험을 반복한다.
반복된 별도 WATER 명령, 중복 command worker, relay 고착·전원 장애는 duration 숫자 검증과 별도로 점검한다.
```

### J.9 [점검] 보안
```text
1. JWT/DB/OAuth secret 외부화와 새 JAR의 legacy AWS key 제거 필요(AWS SDK는 기본 credential chain 전환 완료)  2. DeviceResDto/PumpChannelResDto deviceKey 제거 완료
3. /api/ai/** `X-AI-Worker-Secret` 인증 완료  4. Flutter token substring 및 변경 요청 body 로그 제거 완료  5. ESP/Pi 자격증명 외부화 필요
6. Pi MJPEG 접근 통제 필요  7. Lightsail 3306/8080/9000 제한(Pi 경로 조정 후)  8. Backend 자동복구 구성 필요
9. 관리자 jwt_token cookie Secure; SameSite=Strict 추가 완료(HttpOnly/CSRF는 별도 검토)  10. 서버측 로그아웃/토큰 무효화는 User.tokenVersion 방식으로 구현됨
11. AI 작업명과 exact S3 URL/key·MIME·확장자·20MiB 제한은 완료됐으나 /process endpoint 인증은 미해결
12. AI Worker의 s3:GetObject 코드는 구현됐으나 configured bucket 부재로 live 권한은 미검증. bucket 재생성 후 동일 서비스 identity·bucket·region·known object로 확인
13. private bucket이면 Flutter naked imageUrl/aiImageUrl 전달 방식을 public object·presigned URL·Backend proxy·CDN 중 결정
```

---

## K. 운영 인프라 확정 정리

### K.1 운영 전체 구조
```text
[앱/웹] → Cloudflare → Lightsail Nginx:443(Certbot) → Spring Boot:8080(screen에서 java -jar 수동 실행)
                                                          → MySQL / S3 / DeviceCommand

[Pi] (systemd 2개 + cron)
  greenlink-command.service → command_worker.py (3초 polling, Backend 8080 직접)
  greenlink-stream.service → stream_server.py (0.0.0.0:8000 MJPEG)
  cron run_sensor.sh(10분) → sensor_main.py → POST /api/iot/raspberry/environment
  cron run_camera.sh(09·21시) → camera_main.py → 내부 /stream.mjpg 추출 → 좌/우 crop
      → POST /api/iot/plant-images → ai_trigger → POST {AI_WORKER}/process(9000 직접)
  cloudflared(127.0.0.1:20241) → 카메라 외부 스트림 tunnel(세부 추가 확인)

[ESP32] → POST /api/iot/esp/soil-moisture (X-DEVICE-KEY, 10분)

[Lightsail AI Worker] greenlink-ai.service → uvicorn 0.0.0.0:9000
  → remove_pot(u2netp+0.24 trim) → gpt-image-1.5 edit → S3 → Backend callback
```

### K.2 방화벽 (Lightsail)
| 포트 | 용도 | 현재 | 조치 |
| --- | --- | --- | --- |
| 22 | SSH | Any IPv4 | 관리자 IP 제한 권장 |
| 80 | HTTP | Any IPv4 | redirect/challenge 유지 |
| 443 | HTTPS | Any IPv4 | 유지 |
| 3306 | MySQL | Any IPv4 | **위험, 제한 필요** |
| 8080 | Spring Boot | Any IPv4 | Pi 직접 호출 중 → 경로 조정 후 제한 |
| 9000 | AI Worker | Any IPv4 | Pi 직접 호출 중 → 경로 조정 후 제한 |

UFW inactive, AWS CLI 미설치.

### K.3 우선순위 액션
1. (높음) JAR 내부 secret 외부화
2. (높음) 3306 외부 공개 제거
3. (높음) 8080/9000 Pi 경로 재설계 후 제한
4. (완료) 센서 refresh 계약 정리(GAP-01/02)
5. (완료) 급수 duration 최대 1초 fail-close를 Backend/Pi 양쪽에 구현(GAP-04)
6. (미완료) Backend systemd 등록 또는 동등한 자동복구 구성
7. (부분 완료) wateringSafetyEnabled 설정·수동 급수 반영, 자동 safety 조건 정리는 잔여(GAP-03)
8. (완료) WATERING/GROW_PLANT 퀘스트 연결(GAP-05)
9. (부분 완료) 관리자 cookie 보안(GAP-06: Secure/SameSite 완료, HttpOnly/CSRF 별도 검토)
10. (완료) snapshot/alpha/compose 보조 파일 정리(GAP-07 포함)
11. (높음) AI `/process` endpoint 인증. 원본 exact S3 host/key 제한과 직접 `get_object`는 완료
12. (높음) bucket 재생성 후 AI Worker 실행 identity의 `s3:GetObject` live 확인
13. (높음) 펌프 유량·안전 급수량·배수 실측 후 현재 1초 상한의 적정성 검증. 변경 시 Backend/Pi 동시 반영
14. (높음) private bucket 운영 시 Flutter 이미지 전달 정책 결정

### K.4 잔여 확인 필요
- Certbot 자동갱신 timer/cron 상태
- Pi cloudflared tunnel 이름/외부 도메인/라우팅, stream 외부 공개 범위
- Cloudflare 콘솔(DNS/SSL모드)
- waterCooldownMinutes/lightCooldownMinutes Entity 기본값(현재 API 문서 기준)
- LIGHT 명령은 duration null이며 Pi의 1초 fallback은 WATER의 `durationSeconds` key가 없을 때만 사용
- bucket 재생성 후 AI Worker 실행 identity와 원본 prefix에 대한 `s3:GetObject` 실권한. 동일 bucket/region·known object·서비스 credential chain으로 검증
- private bucket에서 Flutter naked `imageUrl`/`aiImageUrl`을 전달할 방식
- 펌프별 유량, 호스 높이, 화분별 안전 급수량·배수와 반복 명령/중복 worker 위험. 교정 전에는 현재 Backend/Pi 1초 fail-close 상한 유지

---

## 최신 기준 요약본

1. **핵심 목적**: 앱 식물 육성 + 실 재배 센서/제어 + AI 이미지 변환을 IoT로 연결
2. **사용 기술**: Java17/Spring Boot 4.0.6/JPA/Security/JWT/BCrypt/S3, MySQL, Flutter(Dart^3.9.2)/Kakao/Google, ESP32(Arduino/PlatformIO), Pi(Python/Flask/Picamera2/gpiozero), Ubuntu AI(FastAPI/rembg u2netp/OpenAI gpt-image-1.5/boto3)
3. **확정 기능**: 가입/로그인/OAuth/JWT, 회원 기능(비밀번호 변경/회원 탈퇴/서버 로그아웃), 식물(식재/상태 갱신 후 조회/수확/별명), 인벤토리(화분/영양제), 퀘스트(월간 만료 포함, ATTEND/HARVEST/WATERING/GROW_PLANT 진행), 현재 연속 출석, 도감, IoT 구성, ESP 토양/Pi 환경 수집, 이미지 업로드/S3, 수동 물주기/조명, 자동 급수/조명, 자동화 학습(통계), AI 변환, MJPEG, 관리자 REST+Thymeleaf
4. **부분 확인**: 내 정보 화면 연계, IoT 구성 권한 범위, 물부족 UI 상수(Backend와 별개)
5. **과거엔 있으나 현재 없음/정정**: FCM(미구현 확정), camera_main --plant(미지원), ESP 직접 펌프(없음), 자체 ML(없음), 친구/공유/그림판(없음), alpha/pot 합성(폐기)
6. **보류/폐기**: alpha_composite/compose_pot/pot_base/ai_background_remove 삭제됨, camera_snapshot_main 삭제 완료(GAP-07 해소), 팬 제어(없음)
7. **서버/DB/배포**: Lightsail / Cloudflare→Nginx(443,Certbot)→Spring Boot(127.0.0.1:8080, `screen` 수동 실행) / MySQL(ddl-auto:update) / secret은 JAR 내부(외부화 필요) / CI/CD 미사용
8. **프론트**: setState 중심(provider 선언만), ApiClient+JWT+DELETE, Settings에서 비밀번호 변경/탈퇴/서버 로그아웃 연결. token 및 POST/PATCH/DELETE body 로그 제거 완료. 전역 401 이동·Android 인터넷 권한·API 계약 보정 반영. GAP-01/02/04/05 해소, GAP-03 부분 해소. DebugPanel 삭제
9. **백엔드**: ApiResponse<T>, JWT(헤더+jwt_token cookie, tokenVersion 무효화), 자동화는 통계/규칙. 위험: JAR secret(외부화 필요). deviceKey 응답 제거 완료, AI callback 인증 완료
10. **Pi**: systemd 2개(Restart=always/5s)+cron(센서10분/카메라09·21시), stream 8000, polling 3초, GPIO(LED27/펌프22·23/DHT4/BH1750 0x23), Backend8080·AI9000 직접. WATER는 key 누락만 1초 fallback, 그 외 `0 < duration <= 1` fail-close
11. **ESP32**: GPIO34 ADC, 10분, soil-moisture POST, 펌프 제어 없음, Wi-Fi 60회 후 restart
12. **Ubuntu AI**: greenlink-ai.service, uvicorn 0.0.0.0:9000, 작업명 이중 검증, exact configured S3 URL/prefix의 boto3 `get_object` + MIME/확장자/20MiB 선언·stream fail-close 검증, gpt-image-1.5 edit(image 2장/prompt/input_fidelity=high, 투명 파라미터 없음). `/process` 인증과 live `s3:GetObject` 권한 확인은 잔여
13. **AI 이미지**: remove_pot(u2netp/ALPHA_THRESHOLD=12/FALLBACK_TRIM_RATIO=0.24/BOTTOM_PAD_PX=28) 전처리 투명화 → OpenAI edit → PNG → S3. "OpenAI가 투명 PNG 생성"은 오류
14. **발표/시연**: 데모 가능 기능과 GAP 구분 필수. Nginx/HTTPS 운영 확정
15. **판넬 수정**: 이미지/AI 흐름의 "Server"=AI Worker 명확화, ESP32 표기 추가, (Nginx+HTTPS 수정 불필요)
16. **다음 작업 우선 확인**: 8개 기준 문서 → GAP_DECISION_REVIEW → 본 통합본 → GAP/보안 액션 → 운영 잔여 확인
17. **절대 바꾸면 안 되는 것**: AI 활성 파이프라인(투명화=전처리, OpenAI에 transparent/png 추가 금지), ESP 직접 POST, DeviceCommand 폴링, Pi MJPEG route 5개, AI callback 통지 구조, X-DEVICE-KEY, ApiResponse<T>, Pi의 8080/9000 직접 호출(방화벽 변경 시 경로 먼저 조정)
18. **확인 필요**: Certbot 자동갱신 상태, Pi cloudflared tunnel 세부, Cloudflare 콘솔, cooldown Entity 기본값, GAP-06 보안 정책, bucket 재생성 후 AI Worker `s3:GetObject` live 권한, private bucket의 Flutter 이미지 전달 방식, 현재 펌프 1초 상한의 유량 교정과 중복 worker/반복 명령 위험

---

*본 문서는 codex.zip 없이 8개 기준 markdown + GAP_DECISION_REVIEW.md + 소스코드 확정값 + 최종 판넬을 현재 제공 파일 기준으로 정리한 결과입니다. 추측 없이, 확인되지 않은 항목은 "확인 필요"로 표시했습니다.*

> **2026-11 변경**: AI 이미지 변환(OpenAI + rembg, Ubuntu AI Worker, `/api/ai/**`, `AiPlantImage`)과 AWS S3 저장은 제거되었습니다. 현재는 Raspberry Pi가 매일 09:00 실시간 영상에서 한 장을 캡처해 업로드하고, 백엔드가 서버 디스크(Docker 볼륨)에 저장해 `/images/**`로 제공하며 앱 썸네일로 씁니다. 재배기 1대 = 식물 1개 구성입니다. 아래 본문의 AI/S3 관련 내용은 이전 구성 기록입니다.

# GreenLink 기능 명세서

## 1. 문서 목적과 범위

이 문서는 GreenLink 전체 소스에 구현된 기능을 사용자/장치/운영자 관점에서 재구성한 현행 기능 명세서입니다. 현행 기준일은 2026-07-24입니다. 계획된 기능을 추정해 기술하는 것이 아니라, Backend Service와 Domain, Flutter 화면/Service, ESP firmware, Raspberry Pi 실행 코드, Ubuntu AI Worker에서 실제로 확인되는 동작을 기준으로 합니다.

| 영역 | 기능 책임 |
| --- | --- |
| Flutter App | 로그인, 육성/인벤토리/도감/퀘스트 UI, IoT 모니터링 및 제어 UI |
| Backend | 계정, 마스터/사용자 데이터, 장치 구성, 센서 저장, 명령 생성, 자동화, AI 결과 저장 |
| ESP32 | 토양 수분 측정과 직접 서버 전송 |
| Raspberry Pi | 환경 센서, 카메라 stream/업로드, 펌프/조명 실행, AI 작업 요청 |

API의 필드와 HTTP 계약은 별도 문서 [API_SPECIFICATION.md](API_SPECIFICATION.md)를 참조합니다.

## 2. 시스템 목적

GreenLink는 사용자가 앱에서 가상 육성 흐름과 실제 식물 재배 데이터를 함께 관리하도록 구성된 시스템입니다. 확인된 핵심 목적은 다음과 같습니다.

* 사용자가 계정을 만들고 씨앗, 화분, 영양제 기반의 식물 육성을 수행합니다.
* 센서가 측정한 온도, 습도, 조도, 토양 수분을 앱에서 조회합니다.
* 사용자가 물주기와 조명을 요청하거나, 설정한 자동화 기준으로 서버가 명령을 생성합니다.
* Raspberry Pi가 실제 펌프와 조명을 제어하고 실행 결과를 서버에 보고합니다.
* 식물 사진은 원본 및 AI 스타일 변환 결과로 앱에 표시될 수 있습니다.
* 출석, 수확, 퀘스트 보상 및 수확 도감을 제공합니다.

## 3. 사용자와 외부 행위자

| 행위자 | 수행 가능 기능 | 인증/식별 |
| --- | --- | --- |
| 비로그인 사용자 | 회원가입, 로그인, OAuth 로그인, 식물/아이템/퀘스트 마스터 조회 | 없음 |
| 일반 사용자 | 본인 식물/아이템/퀘스트/출석/도감, IoT 조회 및 제어, 자동화 설정 | JWT |
| 관리자 | 마스터 데이터 생성, 관리자 웹 관리 화면 | ADMIN JWT 권한 전제 |
| ESP32 센서 장치 | 토양 수분 전송 | 장치 키 |
| Raspberry Pi 장치 | 환경값/이미지 전송, 명령 조회 및 결과 보고, 영상 stream 제공 | Backend 요청은 장치 키; stream 보호는 확인되지 않음 |
| 외부 OAuth 제공자 | 로그인 사용자 프로필 제공 | OAuth 설정 필요 |

## 4. 전체 기능 흐름

```mermaid
flowchart TD
    Signup[회원가입 또는 로그인] --> Inventory[초기/보상 아이템 보유]
    Inventory --> Plant[씨앗 사용 및 식재]
    Plant --> Grow[식물 성장 상태 조회]
    ESP[ESP 토양 센서] --> Back[Backend 센서 저장]
    PI[Pi 환경/카메라] --> Back
    Back --> Monitor[앱 IoT 모니터링]
    Monitor --> Control[수동 물주기/조명 요청]
    Back --> Auto[자동화 조건 판단]
    Control --> Cmd[장치 명령 생성]
    Auto --> Cmd
    Cmd --> PI
    PI --> Physical[펌프/조명 실행 및 완료 보고]
    AI --> Back
    Grow --> Harvest[수확]
    Harvest --> Collection[도감 반영]
    Harvest --> Quest[퀘스트 진행/보상]
    Attend[출석] --> Quest
```

## 5. 기능 목록 요약

| ID | 기능명 | 주 사용 주체 | 구현 상태 | 주요 근거 |
| --- | --- | --- | --- | --- |
| F-AUTH-01 | 일반 회원가입/로그인 | 사용자 | 구현됨 | `AuthService`, 인증 화면 |
| F-AUTH-02 | Kakao/Google OAuth 로그인 | 사용자 | 구현 코드 있음, 설정 필요 | OAuth service/client, Flutter auth |
| F-USER-01 | 내 정보 및 닉네임 수정 | 사용자 | Backend 구현됨 | `UserController`, `UserService` |
| F-PLANT-01 | 식재, 성장 표시, 별명, 수확 | 사용자 | 구현됨 | `UserPlantService`, Flutter screens |
| F-ITEM-01 | 인벤토리, 화분, 영양제 | 사용자 | 구현됨 | `UserItemService` |
| F-QUEST-01 | 퀘스트 목록/상세/보상 | 사용자 | 구현됨 | `UserQuestService` |
| F-ATTEND-01 | 출석과 연속 출석 | 사용자 | 구현됨 | `AttendService` |
| F-COLL-01 | 수확 도감 | 사용자 | 구현됨 | `CollectionService` |
| F-IOT-SETUP-01 | 공간/장치/펌프 연결 구성 | 로그인 사용자 | 구현됨, 권한 범위 주의 | `IotSetupService` |
| F-SENSOR-01 | 토양 수분 수집 | ESP32 | 구현됨 | `main.cpp`, `IotDeviceDataService` |
| F-SENSOR-02 | 환경 데이터 수집 | Pi | 구현됨 | `sensor_*.py`, `IotDeviceDataService` |
| F-CAMERA-01 | 실시간 MJPEG 및 원본 사진 저장 | Pi/App | 구현됨 | `stream_server.py`, `camera_main.py` |
| F-CONTROL-01 | 수동 물주기/조명 | 사용자/Pi | 구현됨 | `IotAppService`, `command_worker.py` |
| F-AUTO-01 | 자동 물주기/조명 | Backend/Pi | 구현됨 | `AutomationService` |
| F-AUTO-02 | 데이터 기반 자동화 임계치 산출 | 사용자/Backend | 구현됨 | `AutomationLearningService` |
| F-ADMIN-01 | 마스터/사용자/장치 관리 | 관리자 | 부분 구현 | `AdminController`, `AdminWebController` |
| F-GAP-01 | 센서 즉시 갱신 UI | 사용자/Pi | 구현됨 | Flutter 버튼, Backend refresh endpoint, `SENSOR_REFRESH` 명령, Pi 분기 |

## 6. 인증 및 사용자 기능

### F-AUTH-01 일반 회원가입과 로그인

| 항목 | 명세 |
| --- | --- |
| 목적 | 일반 사용자가 계정을 생성하고 인증된 앱 기능에 진입하게 합니다. |
| 시작 조건 | 가입 시 이메일/비밀번호/닉네임 입력, 로그인 시 등록된 `LOCAL` 계정 존재 |
| 입력 | 가입: 이메일, 비밀번호, 닉네임. 로그인: 이메일, 비밀번호 |
| 처리 | 이메일 중복 검사, 비밀번호 BCrypt 저장/검증, `LOCAL` 계정만 일반 로그인 허용, 로그인 시 JWT 생성 |
| 회원가입 후 처리 | 기본 씨앗 1종과 기본 화분 1종을 보유 아이템으로 지급하고 활성 업적 퀘스트를 사용자에게 생성 |
| 출력 | 가입 정보와 지급 아이템(`userItemId`와 `itemId` 구분), 또는 로그인 접근 토큰 및 사용자 정보 |
| 실패 조건 | 중복 이메일, 잘못된 로그인, 기본 마스터 아이템 미등록 |
| 관련 UI | `LoginPage`, `SignupPage`, `SplashPage` |
| 관련 API | `POST /api/auth/signup`, `POST /api/auth/login` |

**승인 기준**

1. 유효한 가입 요청은 새 사용자와 초기 아이템 데이터를 만듭니다.
2. 이미 존재하는 이메일 가입은 거부됩니다.
3. 올바른 자격 증명을 가진 `LOCAL` 계정의 일반 로그인만 접근 토큰을 반환하며 OAuth 계정은 이 경로에서 거부됩니다.
4. 저장된 토큰이 있는 앱은 메인 화면으로 이동하며, API 401 이후 로그인 화면으로 복귀합니다.

**주의사항**

* 기본 지급 마스터 아이템이 DB에 선행 생성되어 있어야 합니다.
* Flutter는 접근 토큰을 로컬 일반 저장소에 저장합니다. 공통 API Client는 현재 요청 body와 token 값을 로그에 출력하지 않지만 URL/응답 상태와 일부 인증 진단 로그는 남기므로 배포 로그 정책이 필요합니다.

### F-AUTH-02 OAuth 로그인

| 항목 | 명세 |
| --- | --- |
| 목적 | Kakao 또는 Google 계정으로 인증하고 GreenLink 사용자를 연결/생성합니다. |
| 입력 | 제공자의 인가 코드, redirect URI |
| 처리 | 외부 provider 토큰/프로필 획득, provider 식별자로 기존 계정 조회 또는 생성, 신규 계정에는 무작위 UUID 기반 내부 비밀번호 해시 저장, 초기 아이템/업적 보정, JWT 발급 |
| 출력 | 일반 로그인과 동일한 로그인 응답 |
| 전제 | provider client 설정값과 플랫폼 등록이 외부에서 올바르게 제공되어야 함 |
| 관련 API | `POST /api/auth/oauth/kakao`, `POST /api/auth/oauth/google` |

외부 OAuth 구성의 실제 작동값과 배포 redirect 설정은 코드상 확인되지 않습니다.

### F-USER-01 내 정보

Backend에는 내 정보 조회 및 닉네임 변경 기능이 존재합니다. Flutter의 API 경로 상수에는 내 정보 endpoint가 있으나, 현재 확인한 주요 앱 서비스 구조에서 이 기능의 완전한 화면 연계 여부는 명확히 확인되지 않습니다.

## 7. 식물 육성 및 아이템 기능

### F-PLANT-01 씨앗 식재와 성장 상태

| 항목 | 명세 |
| --- | --- |
| 목적 | 사용자가 보유한 씨앗을 실제 키우는 식물 인스턴스로 전환합니다. |
| 시작 조건 | 로그인 사용자에게 `OWNED` 상태의 `SEED` 아이템이 있으며, 그 씨앗 마스터가 Plant에 연결되어 있음 |
| 입력 | 사용할 user item ID, 선택 별명 |
| 처리 | 씨앗 소유/유형/상태 검사, `UserPlant` 생성, 씨앗을 사용 상태로 변경 |
| 상태 | `GROWING`에서 성장일이 지나면 조회 시 `HARVESTABLE`, 수확 후 `HARVESTED`. 상태 필터 목록도 전체 상태 갱신 후 필터링 |
| 출력 | 식물 ID, 종류, 별명, 상태, 식재/예상 수확 가능 시각 |
| 관련 API | 사용자 식물 생성/목록/상세/별명/수확 API |
| 관련 UI | 홈, 식물 목록, 식재 화면, 식물 상세 |

```mermaid
stateDiagram-v2
    [*] --> GROWING: OWNED SEED 사용 및 식재
    GROWING --> HARVESTABLE: 성장일 경과 후 조회 시 상태 갱신
    HARVESTABLE --> HARVESTED: 사용자 수확 요청
```

**수확 처리**

1. Backend가 사용자 소유 식물을 조회합니다.
2. 오늘 날짜 기준으로 수확 가능 상태를 갱신합니다.
3. 아직 성장 중이거나 이미 수확된 식물은 거부합니다.
4. 수확 시각과 `HARVESTED` 상태를 저장합니다.
5. `TargetType.HARVEST`와 `TargetType.GROW_PLANT` 퀘스트 진행도를 1씩 증가시킵니다.
6. 컬렉션 조회 시 수확 기록으로 표시됩니다.

**코드상 제한**

현재 `GROW_PLANT` 진행도는 식재 시점이 아니라 수확 성공 시점에 증가합니다.

### F-ITEM-01 인벤토리와 아이템 사용

| 세부 기능 | 입력 | 처리 규칙 | 결과 |
| --- | --- | --- | --- |
| 아이템 목록 | 선택 item type/status | 마스터 아이템별로 보유 row를 그룹화하고 상태별 count 계산 | 앱 인벤토리 표시 |
| 화분 장착 | 보유 화분, 대상 식물 | `OWNED` 상태의 `POT`만 가능; 해당 식물의 기존 장착 화분은 해제 | `EQUIPPED` |
| 화분 해제 | 장착 중 화분 | `EQUIPPED` 상태 `POT`만 가능 | 다시 소유 상태 처리 |
| 영양제 사용 | 보유 영양제, 대상 식물 | `OWNED` 상태 `NUTRIENT`만, `GROWING` 식물에만 가능 | 사용 상태와 대상 식물 연결, 수확까지 남은 기간 1일 단축 |
| 씨앗 사용 | 보유 씨앗 | 식재 기능에서만 처리 | `USED` 및 새 식물 |

영양제 1개는 수확 가능 날짜를 하루 앞당깁니다(`UserPlant.growthBoostDays`). 수확 가능 날짜는 식재일보다 앞당겨지지 않으며, 앞당긴 결과 오늘이 되면 즉시 `HARVESTABLE`이 됩니다. 수확이 끝난 식물에는 화분을 장착할 수 없습니다.

## 8. 퀘스트, 출석 및 도감 기능

### F-QUEST-01 퀘스트 생성, 진행 및 보상

| 항목 | 명세 |
| --- | --- |
| 목적 | 기간형 또는 업적형 목표와 아이템 보상을 제공합니다. |
| 퀘스트 구분 | 일간, 주간, 월간, 업적 |
| 반복 주기 | 일간, 주간, 월간, 반복 없음 |
| 기간 계산 | 일간은 시작 +1일, 주간은 +7일, 월간은 달력 기준 +1개월, 반복 없음은 만료 없음 |
| 상태 | 진행 중, 수령 가능, 완료, 만료 |
| 목록 처리 | 현재 기간에 필요한 사용자 퀘스트를 생성하고, 지난 진행 중 기간형 기록은 만료 처리하며 현재 목록에서 숨김 |
| 상세 처리 | 이미 알고 있는 사용자 퀘스트 ID의 상세는 과거 기간도 조회 가능 |
| 보상 처리 | 현재 노출 가능한 상태이며 수령 가능 상태인 경우에만 보상 아이템 row를 수량만큼 생성 |

### 확인된 진행 Trigger

| TargetType | 트리거 | 상태 |
| --- | --- | --- |
| `ATTEND` | 오늘 출석 성공 시 `AttendService` | 구현됨 |
| `HARVEST` | 식물 수확 성공 시 `UserPlantService` | 구현됨 |
| `WATERING` | Pi가 WATER 명령 SUCCESS 보고 시 `IotCommandService` | 구현됨 |
| `GROW_PLANT` | 식물 수확 성공 시 `UserPlantService` | 구현됨 |

### F-ATTEND-01 출석

| 항목 | 명세 |
| --- | --- |
| 입력 | 오늘 출석 요청, 또는 조회할 연/월 |
| 처리 | 사용자-날짜 중복을 방지하고, 전날 출석이 있으면 streak를 증가시킴 |
| 출력 | 오늘 출석/연속 횟수 또는 월별 출석 목록과 current streak. 마지막 출석이 오늘/어제보다 오래되면 current streak는 0 |
| 연계 | 성공한 오늘 출석은 `ATTEND` 퀘스트 진행도를 1 증가 |
| 실패 | 같은 날짜 두 번째 출석 거부; 조회 시 year/month 중 하나만 제공하면 거부 |

### F-COLL-01 수확 도감

| 항목 | 명세 |
| --- | --- |
| 목적 | 모든 식물 마스터에 대해 사용자의 수확 여부와 기록을 제공합니다. |
| 목록 | 수확 여부, 수확 횟수, 최초 수확 시각을 표시 |
| 상세 | 식물 설명과 사용자가 수확한 개별 식물 목록/식재 및 수확 시각 제공 |
| 데이터 원천 | `Plant` 마스터와 `HARVESTED` 사용자 식물 기록 |

## 9. IoT 설치와 장치 등록 기능

### F-IOT-SETUP-01 재배 공간 구성

IoT 동작 전 필요한 연결 관계는 다음과 같습니다.

```mermaid
erDiagram
    GROW_SPACE ||--o{ GROW_SPACE_PLANT : contains
    USER_PLANT ||--o| GROW_SPACE_PLANT : placed_in
    GROW_SPACE ||--o{ IOT_DEVICE : has_pi
    USER_PLANT ||--o{ IOT_DEVICE : has_esp
    GROW_SPACE ||--o{ PUMP_CHANNEL : has
    USER_PLANT ||--o| PUMP_CHANNEL : waters
    IOT_DEVICE ||--o{ PUMP_CHANNEL : executes
```

| 구성 기능 | 조건 | 사용 목적 |
| --- | --- | --- |
| 재배 공간 생성 | 이름 중복 불가 | Pi 환경값과 식물/펌프를 묶는 단위 |
| 식물-공간 연결 | 로그인 사용자의 식물, 한 식물의 중복 연결 불가 | IoT 조회/이미지/자동화 기준 |
| Raspberry Pi 등록 | 공간 ID 필수, 특정 식물 ID를 직접 가질 수 없음 | 공간 공통 센서와 명령 실행 |
| ESP32 등록 | 사용자 식물 ID 필수, 선택 공간은 식물 연결과 일치해야 함 | 식물별 토양 수분 |
| 펌프 채널 등록 | 공간/식물/Pi 연결 일치, 식물당 1개 | WATER 명령 GPIO 정보 |

**권한 및 보안상 현행**

* IoT 구성 API는 ADMIN 전용으로 제한되지 않고 로그인 사용자 경로로 분류되어 있습니다.
* 목록 서비스는 전체 장치/펌프 데이터를 반환하며 사용자별 범위 제한이 확인되지 않습니다.
* 장치/펌프 응답 DTO에서는 장치 인증 키를 제외합니다. DB의 키 저장과 장치 요청 검증은 유지됩니다.

## 10. 센서 수집 및 모니터링 기능

### F-SENSOR-01 ESP 토양 수분 수집

| 항목 | 명세 |
| --- | --- |
| 장치 | PlatformIO Arduino 기반 ESP32 |
| 센서 입력 | GPIO 34 analog 입력 |
| 측정 처리 | 여러 raw 샘플을 평균한 후 건조/습윤 calibration으로 0~100% 수분값 환산 |
| 전송 주기 | 부팅 직후 전송 후 코드상 10분 간격 |
| 통신 | Wi-Fi를 통해 Backend 토양 수분 API로 JSON POST, 장치 키 header 포함 |
| 서버 처리 | 활성 ESP와 연결 식물을 확인하고 `EspSensorData` 저장, 연결 시각 갱신, 자동 급수 평가 |
| 오류 처리 | Wi-Fi 연결 실패 시 재연결/장치 재시작; 실패 payload 영속 큐는 없음 |

ESP와 Pi 사이에 직접 통신하는 기능은 코드상 확인되지 않습니다.

### F-SENSOR-02 Pi 환경 데이터 수집

| 항목 | 명세 |
| --- | --- |
| 입력 장치 | DHT22 온도/습도, BH1750 조도 |
| 측정 처리 | DHT 측정 재시도와 값 범위 검사, 조도 I2C 측정, 측정 시각 부여 |
| 전송 | Backend 환경 데이터 API로 JSON POST, 장치 키 header |
| 서버 처리 | Pi 및 공간 연결 확인, `RaspberrySensorData` 저장, 자동 조명 평가 |
| 실행 단위 | `sensor_main.py`는 1회 업로드; 반복 실행 등록은 저장소에서 확인되지 않음 |

### F-MONITOR-01 앱 IoT 상태 조회

| 표시 데이터 | 출처 | UI 사용 |
| --- | --- | --- |
| 온도, 습도, 조도 | 공간별 최신 Pi 데이터 | 상태 카드 |
| 토양 수분 raw/percent | 식물별 최신 ESP 데이터 | 상태/물 부족 또는 과습 안내 |
| 일일 사진 | Pi 매일 09:00 캡처 업로드 | 홈·상세 썸네일 |
| 실시간 영상 | Pi MJPEG stream | IoT 화면 영상 위젯 |

Flutter가 사용하는 토양 안내 기준은 앱 코드의 상수 판정이며, Backend 자동 급수 설정값과 동일한 규칙이라고 보장되지는 않습니다.

## 11. 제어 명령 기능

### F-CONTROL-01 수동 급수와 조명

| 항목 | 급수 | 조명 켜기/끄기 |
| --- | --- | --- |
| 시작 주체 | 앱 사용자 | 앱 사용자 |
| Backend 검증 | 소유 식물, 공간, 활성 펌프/Pi, 처리 중 급수 없음 | 소유 식물, 공간, 활성 Pi, 처리 중 조명 없음 |
| 생성 명령 | `WATER` | `LIGHT_ON`, `LIGHT_OFF` |
| 실행 장치 | Raspberry Pi 펌프 relay | Raspberry Pi LED relay |
| 결과 저장 | Pi가 processing/complete 보고 | Pi가 processing/complete 보고 |

```mermaid
sequenceDiagram
    participant U as 사용자
    participant App as Flutter
    participant B as Backend
    participant Pi as Pi Command Worker
    participant HW as Relay/Pump/Light
    U->>App: 물주기 또는 조명 조작
    App->>B: 제어 API 요청
    B->>B: 연결/중복 명령 검증 후 PENDING 저장
    B-->>App: command 응답
    Pi->>B: pending polling
    B-->>Pi: 명령 전달
    Pi->>B: PROCESSING 보고
    Pi->>HW: GPIO 동작
    Pi->>B: SUCCESS 또는 FAILED 보고
```

### 센서 새로고침

Flutter IoT 화면의 새로고침 버튼은 `POST /api/user-plants/{id}/iot/refresh`를 호출합니다. Backend는 소유 식물, 연결 공간, Pi 장치, 진행 중 중복 명령을 검증한 뒤 `CommandType.SENSOR_REFRESH`의 `PENDING` 명령을 생성합니다. Pi command worker는 기존 `SENSOR_REFRESH` 분기에서 센서를 읽고 업로드한 뒤 SUCCESS를 보고하며, Flutter는 요청 후 2.5초 뒤 latest API를 재조회합니다.

### 명령 상태 규칙

| 현재 상태 | 동작 | 결과 상태 | 조건 |
| --- | --- | --- | --- |
| 신규 | 명령 생성 | `PENDING` | 앱/자동화 검증 통과 |
| `PENDING` | Pi 처리 시작 | `PROCESSING` | 해당 Pi 장치 키와 명령 소유 일치 |
| `PROCESSING` | Pi 성공 완료 | `SUCCESS` | `success=true` 결과 |
| `PROCESSING` | Pi 실패 완료 | `FAILED` | `success=false` 결과 |
| 대기/처리 중 | entity cancel 메서드 | `CANCELLED` | 이를 노출하는 API는 확인되지 않음 |

### 현행 제어 제한과 불일치

* 급수 duration의 Backend 생성값과 허용 최대값은 모두 1초입니다. WATER 생성자는 `0 < durationSeconds <= 1`을 강제합니다.
* Pi worker는 key가 없는 경우에만 1초 fallback을 적용합니다. null·비수치·불리언·0 이하·1초 초과·NaN·무한대는 보정하지 않고 펌프 호출 전에 거부하며 명령을 `FAILED`로 보고합니다.
* 수동/자동 구분 없이 WATER 명령이 SUCCESS로 완료되면 `WATERING` 퀘스트 진행도가 증가합니다.

## 12. 자동화 기능

### F-AUTO-01 설정 기반 자동 급수

| 항목 | 명세 |
| --- | --- |
| Trigger | ESP 토양 수분 데이터 저장 직후 |
| 활성 조건 | 해당 식물 설정의 `autoWaterEnabled=true` |
| 판단값 | 설정 수분 임계치 또는 사용 가능한 학습 모델 추천값 |
| 실행 조건 | 수분값이 임계치 이하, 대기/처리 중 WATER 없음, cooldown 경과, 공간/Pi/펌프 연결 존재 |
| 실행 결과 | Pi 대상 `WATER` 명령 생성 및 실행 로그 저장 |
| Skip 결과 | 비활성, 센서값 없음, 임계치 미충족, 중복, cooldown, 장치 미구성에 대해 skip 로그 저장 |

### F-AUTO-01 설정 기반 자동 조명

| 항목 | 명세 |
| --- | --- |
| Trigger | Pi 환경 데이터 저장 직후 |
| 적용 단위 | 센서는 GrowSpace 단위이나 설정과 로그는 연결된 각 UserPlant 단위 |
| 활성 조건 | 식물 설정의 `autoLightEnabled=true` |
| 시간 조건 | 동작 시간 밖이면 `LIGHT_OFF` 후보 |
| 조도 조건 | 시작 시간 범위 안에서 조도가 ON 임계치 이하이면 ON, OFF 임계치 이상이면 OFF |
| 방지 조건 | 진행 중 ON/OFF 명령 또는 최근 cooldown 내 명령 |
| 결과 | 명령 생성 또는 skip 로그 |

조명은 공간 장치인데 중복/cooldown 검사가 식물별 명령 기준으로 수행됩니다. 동일 공간에 여러 식물 설정이 존재할 때 물리 조명에 상충 명령이 생기지 않는지는 추가 검증이 필요합니다. 이는 코드 구조에서 도출되는 운영 위험입니다.

### F-AUTO-02 데이터 기반 임계치 산출

| 항목 | 명세 |
| --- | --- |
| 시작 | 사용자가 자동화 학습 API 요청 |
| 분석 기간 | 최근 14일 |
| 입력 | ESP 수분 데이터, Pi 조도 데이터, 물주기 명령 기록 |
| 최소 조건 | 설정의 `minLearningDataCount`; 기본 30개의 토양 데이터 |
| 데이터 부족 결과 | `INSUFFICIENT_DATA` 모델 저장 |
| 수분 추천 | 물주기 직전 평균 수분에 보정값을 더하고 코드 범위로 제한 |
| 조도 추천 | 충분한 조도 데이터에서 낮은/높은 분위수 기반 ON/OFF 임계치 산출 |
| 신뢰도 | 토양/조도 데이터 수, 물주기 명령 수, 수분 회복 샘플 수 가중 계산 |
| 설정 자동 반영 | `autoOptimizeEnabled=true`이며 confidence가 기준 이상이면 추천 임계치를 설정에 적용 |

이 기능은 코드상 통계 규칙 기반 임계치 산출입니다. 별도 학습 파일 또는 외부 머신러닝 모델을 학습하는 기능은 확인되지 않습니다.

### 자동화 설정 화면 계약

Flutter의 `wateringSafetyEnabled` 설정은 Backend `AutomationSetting`에 저장됩니다. 과습 안전 모드가 켜져 있고 최신 토양수분이 `waterThresholdPercent + 10.0` 이상이면 수동 급수는 400 응답으로 차단합니다. 자동 급수는 먼저 학습 모델을 포함한 effective water threshold로 일반 불필요 조건을 검사하고, 이후 설정값 기반 safety threshold를 검사합니다. 기본/RULE_BASED에서는 safety 전용 분기가 사실상 도달하지 않으며, 학습 threshold가 safety threshold 이상일 때 경계 또는 일부 구간에서만 도달할 수 있습니다. 따라서 전용 skip 로그와 규칙 의미가 설정·모델 조합에 따라 달라집니다.

## 13. 카메라와 일일 식물 사진

### F-CAMERA-01 실시간 영상

| 세부 기능 | 처리 |
| --- | --- |
| 실시간 영상 | Pi Flask 서버가 카메라 전체 화면을 MJPEG로 제공하고 Flutter가 byte stream을 파싱해 표시 (재배기 1대 = 식물 1개) |

* 영상 stream endpoint 자체 인증은 없으므로 공개 범위는 Cloudflare Access 등으로 제한합니다.

### F-CAMERA-02 일일 썸네일 사진

| 항목 | 명세 |
| --- | --- |
| 시작 Trigger | Pi cron이 매일 09:00 `camera_main.py` 실행 (`crontab.example`) |
| 캡처 | 로컬 `/stream.mjpg`에서 JPEG 프레임 한 장을 추출 (crop 없음) |
| 업로드 | 장치 키와 multipart 이미지, 식물 ID, 촬영 시각을 Backend `/api/iot/plant-images`로 전송. 성공·실패와 무관하게 로컬 임시 파일 삭제 |
| 저장 | Backend가 형식/크기/MIME을 검사하고 서버 디스크(`GREENLINK_IMAGE_DIR`)에 저장, `PlantImage`에 `/images/userplant/{파일명}` 경로 기록 |
| 제공 | `/images/**`로 인증 없이 제공(30일 캐시). 파일명은 식물 ID·시각·난수라 추측이 어렵습니다 |
| 앱 표시 | IoT 최신 상태의 `latestImage.imageUrl`을 서버 주소와 합쳐 홈·식물 상세 썸네일로 표시, 촬영 날짜 표시. 없으면 식물 기본 이미지 |
| 보관 | 매일 04:00 보관 기간(기본 30일)이 지난 사진의 파일과 레코드를 정리하되 식물별 최신 사진은 남김 |

## 14. 관리자 기능

### F-ADMIN-01 마스터 데이터 관리

| 기능 | REST API | Web UI | 구현된 핵심 처리 |
| --- | --- | --- | --- |
| 식물 등록 | 있음 | 목록/등록 있음 | 이름 중복 검사, 성장일 포함 생성 |
| 아이템 등록 | 있음 | 목록/등록 있음 | 씨앗은 연결 식물 필수, 화분/영양제 생성 |
| 퀘스트 등록 | 있음 | 목록/등록 있음 | 목표/보상/반복 주기 생성, 보상 수량 규칙 검사 |
| 사용자 목록/상세 | REST 확인되지 않음 | 있음 | 조회, role toggle, soft delete |
| IoT 장치 등록 | REST는 구성 API 별도 존재 | 관리자 웹 있음 | 장치 유형별 연결 생성 |

### 관리자 접근 제한

* `/api/admin/**`와 로그인 화면 외 `/admin/**`는 ADMIN 권한으로 설정되어 있습니다.
* Security의 form login은 비활성화되어 있지만 관리자 로그인 HTML은 `/api/auth/login`에 JSON 요청하여 JWT를 발급받습니다.
* 화면은 JWT를 `Secure; SameSite=Strict`인 `jwt_token` 쿠키에 저장하고 `/admin`으로 이동하며, `JwtAuthenticationFilter`가 쿠키와 ADMIN role을 확인합니다.
* 쿠키는 JavaScript에서 생성하므로 `HttpOnly`를 적용하지 못하는 제약이 있습니다.

## 15. 앱 화면 기능 구성

| 화면 영역 | 사용자 기능 | 연결된 Backend/외부 기능 | 상태 |
| --- | --- | --- | --- |
| Splash / Login / Signup | 자동 로그인 분기, 일반/OAuth 로그인, 가입 | Auth API, 저장 토큰 | 구현됨 |
| Home | 대표/보유 식물, 이미지, 수확 진입 | Home, UserPlant, IoT latest | 구현됨 |
| Inventory | 보유 아이템 필터, 화분/영양제, 식재 이동 | UserItem, UserPlant | 구현됨 |
| Collection | 수확 도감 목록/상세 | Collection API | 구현됨 |
| Quest / Attend | 퀘스트/보상, 출석 달력/오늘 출석 | Quest, Attend API | 구현됨 |
| Plant Detail | 식물 상세, 별명, 수확, IoT/자동화 진입 | UserPlant, IoT, Automation | 구현됨 |
| IoT Status | 센서값, 이미지/영상, 수동 제어, 갱신 버튼 | IoT API, Pi MJPEG | 구현됨 |
| Automation Section | 자동화 toggle/임계치, 학습 모델과 로그 | Automation API | 구현됨 |
| Settings | 비밀번호 변경, 회원 탈퇴, 로그아웃 | 사용자 API, 로컬 토큰 처리 | 구현됨 |

## 16. 상태와 데이터 저장 규칙

### 핵심 상태 모델

| 데이터 | 상태 또는 핵심 속성 | 상태를 바꾸는 기능 |
| --- | --- | --- |
| 사용자 식물 | `GROWING`, `HARVESTABLE`, `HARVESTED` | 조회 상태 갱신, 수확 |
| 사용자 아이템 | `OWNED`, `EQUIPPED`, `USED` | 식재, 화분 장착/해제, 영양제 사용, 보상 |
| 사용자 퀘스트 | `IN_PROGRESS`, `ACHIEVABLE`, `COMPLETED`, `EXPIRED` | 출석/수확/WATER 완료 진행, 기간 만료, 보상 수령 |
| 장치 명령 | `PENDING`, `PROCESSING`, `SUCCESS`, `FAILED`, `CANCELLED` | 앱/자동화 생성, Pi 실행 보고 |
| 자동화 모델 | `INSUFFICIENT_DATA`, `READY`, `FAILED` | 수동 학습 요청 |

### 데이터 이동 경로

| 데이터 | 생성 주체 | 서버 저장 데이터 | 소비 기능 |
| --- | --- | --- | --- |
| 토양 수분 | ESP32 | `EspSensorData` | 앱 상태, 자동 급수, 모델 산출 |
| 온도/습도/조도 | Pi | `RaspberrySensorData` | 앱 상태, 자동 조명, 모델 산출 |
| 원본 사진 | Pi | `PlantImage` + 객체 저장소 URL | 앱 이미지, AI 입력 |
| 명령/결과 | Backend/Pi | `DeviceCommand` | GPIO 실행, 로그/모델 |
| 자동화 판단 | Backend | `AutomationLog` | 앱 자동화 이력 |

## 17. 기능별 미구현 또는 계약 불일치

| ID | 내용 | 근거 | 사용자/운영 영향 |
| --- | --- | --- | --- |
| GAP-01 | 센서 refresh Backend endpoint와 명령 타입 연결 | `POST /api/user-plants/{id}/iot/refresh`, `CommandType.SENSOR_REFRESH`, Pi 기존 분기 | 해소됨 |
| GAP-02 | Pi `SENSOR_REFRESH` 분기까지 서버 명령 생성 경로 연결 | GAP-01과 동일 작업으로 Backend 명령 생성 경로 연결 | 해소됨 |
| GAP-03 | `wateringSafetyEnabled` Backend 반영 | 설정/DTO와 수동 급수 차단은 반영. 자동 safety 전용 분기는 기본/RULE_BASED에서 사실상 도달하지 않고 학습 임계치 조합에 따라 제한적으로만 도달 | 부분 해소 |
| GAP-04 | 급수 생성값·누락 fallback·허용 최대값을 1초로 통일 | Backend WATER 생성자가 범위를 강제하고 Pi `resolve_water_duration()`이 key 누락만 1초로 처리하며 invalid/과대값을 펌프 호출 전에 거부 | 코드 안전 상한 해소 / 실물 유량·중복 실행 안전성 별도 |
| GAP-05 | `WATERING`, `GROW_PLANT` 퀘스트 목표 진행 연결 | WATER SUCCESS 시 `IotCommandService`, 수확 시 `UserPlantService`에서 `increaseProgress` 호출 | 해소됨 |
| GAP-06 | 관리자 웹 로그인 완료 흐름 | 로그인 HTML → `/api/auth/login` → JWT cookie → `JwtAuthenticationFilter` | 기능 흐름 해소, JS cookie의 `HttpOnly` 제약은 운영 보안 과제 |
| GAP-07 | Pi snapshot legacy 진입점 정리 | `camera_snapshot_main.py` 삭제 완료 | 해소됨 |

## 18. 보안 및 운영 요구사항

아래는 현재 코드가 기능 수행 과정에서 드러내는 필수 보완 사항입니다.

| 우선순위 | 요구사항 | 현재 코드 근거 |
| --- | --- | --- |
| 높음 | 장치 키, 서버 주소, JWT/SDK/클라우드 설정은 소스 밖에서 주입하고 기존 노출값은 회전해야 함 | 각 영역 코드에 민감 설정 종류 존재 |
| 높음 | IoT 구성 목록 권한을 제한해야 함 | Backend Service가 전체 목록을 반환 |
| 중간 | 앱 진단 로그에 개인정보나 인증 payload를 남기지 않아야 함 | 공통 `ApiClient`의 body/token 값 로그는 제거됨. URL/상태 및 일부 이메일 로그는 남음 |
| 중간 | 영상 stream 접근 통제를 정의해야 함 | Pi stream route 인증 없음 |
| 중간 | Pi/AI 작업의 systemd/cron, 재시작, 로그 보존 및 실패 재시도 정책을 명시해야 함 | 실행 스크립트만 있고 운영 정의 없음 |
| 중간 | 통합 계약 테스트로 Flutter-Backend-Pi enum/DTO를 지속 검증해야 함 | 지급 아이템 ID, 홈 plant ID, 출석 streak, 퀘스트 보상 필드의 알려진 Flutter-Backend 불일치는 수정되었고 Flutter 모델 테스트 5건 추가 |
| 중간 | 자동 제어의 물리·운영 안전을 계속 검증해야 함 | Backend/Pi 최대 1초 guard와 relay `finally` off는 구현됨. 실제 유량 피드백, 중복 worker, 고착 PROCESSING, 전원/릴레이 고장은 별도 |

## 19. 구현 추적표

| 기능 ID | Backend | Frontend | Device / AI |
| --- | --- | --- | --- |
| F-AUTH-01/02 | `AuthController`, `AuthService`, `service/oauth` | `auth_service.dart`, auth screens, `splash_page.dart` | - |
| F-PLANT-01 | `UserPlantController`, `UserPlantService`, `UserPlant` | user plant/home screens | - |
| F-ITEM-01 | `UserItemController`, `UserItemService`, `UserItem` | inventory screens | - |
| F-QUEST-01 | `UserQuestController`, `UserQuestService`, `QuestProgressService` | quest widgets/screens | - |
| F-ATTEND-01 | `AttendController`, `AttendService` | `attend_page.dart` | - |
| F-COLL-01 | `CollectionController`, `CollectionService` | collection screens | - |
| F-IOT-SETUP-01 | `IotSetupController`, `IotSetupService` | 전용 설정 UI 확인되지 않음 | 장치 배포 전제 |
| F-SENSOR-01 | `IotDeviceDataService` | IoT 표시 | `greenlink_esp/src/main.cpp` |
| F-SENSOR-02 | `IotDeviceDataService` | IoT 표시 | Pi `sensor_service.py`, `sensor_uploader.py` |
| F-CAMERA-01 | 이미지 저장 서비스 | `MjpegStreamView`, 상세/IoT UI | Pi stream/camera/uploader |
| F-CONTROL-01 | `IotAppService`, `IotCommandService`, `DeviceCommand` | `iot_status_page.dart` | Pi `command_worker.py`, `relay_control.py` |
| F-AUTO-01/02 | `AutomationService`, `AutomationLearningService` | automation section/cards | ESP/Pi 센서 trigger |
| F-ADMIN-01 | `AdminService`, admin controllers | - | - |

## 20. 정리 요약

GreenLink는 계정과 육성 게임 기능에 물리 센서/제어 및 이미지 AI 처리를 결합한 시스템으로 구현되어 있습니다. 주요 정상 흐름은 회원가입과 식재, ESP/Pi 센서 저장, 앱 모니터링, 수동 또는 자동 명령 생성, Pi GPIO 실행, 사진 업로드와 AI 결과 표시입니다.

GAP-01, 02, 04, 05~07의 확인된 기능 연결은 해소되었고 GAP-03은 수동 급수까지 명확히 반영되어 부분 해소 상태입니다. 2026-07-24 검증 기준으로 Backend H2 `test` profile의 17개 테스트와 `bootJar`, Pi duration/정상·실패 worker 테스트 5개, Ubuntu AI Worker의 S3 URL/GetObject 경계 테스트를 포함한 13개 테스트가 통과했습니다. 실제 AWS bucket은 삭제된 상태라 IAM과 live object 호출은 검증하지 못했습니다. 또한 Flutter SDK가 없는 검증 환경에서는 저장소의 Flutter 테스트 13개를 실행하지 못했으므로 SDK가 있는 CI에서 재검증해야 합니다. 운영 전에는 자동 safety의 이중 임계치와 조건 순서, 실제 펌프 유량·중복 실행/고착 복구, 관리자 JWT cookie 정책, 장치 키 소스 노출과 AI Worker `/process`/영상 접근 인증도 계속 관리 대상입니다.

## 21. 추가로 확인하면 좋은 점

* 관리자 JWT cookie의 `HttpOnly` 적용 방식과 만료/로그아웃 정책 정리.
* `GROW_PLANT` 퀘스트를 현재처럼 수확 시점에 유지할지, 별도 식재 시점으로 분리할지.
* 현재 1초 상한을 늘리기 전에 펌프별 유량, 화분별 안전 급수량, 배수와 연속 명령을 실측할지와 채널별 상한이 필요한지.
* 공간 공용 조명에 여러 식물 설정이 적용될 때의 우선순위 정책.
* 장치 구성/관리 API를 관리자 전용으로 제한할지와 장치 provisioning 절차.
* AI 작업 실패 및 카메라/센서 장애를 사용자에게 노출하는 상태/알림 기능 필요성.

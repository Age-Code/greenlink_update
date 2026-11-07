# GreenLink 하드웨어 연결 가이드 (재배기 1대 = 식물 1개)

이 문서는 실제 재배기를 처음부터 연결하는 순서를 설명합니다. 다루는 범위는 몇 번 핀에 무엇을 꽂는지, 어떤 순서로 켜고 점검하는지입니다.
핀 번호와 동작 방식은 저장소 코드 기준입니다(`greenlink_pi/config.py`, `greenlink_esp/src/main.cpp`).

> **안전 원칙**
> - 배선은 **모든 전원을 뽑은 상태**에서만 합니다(Pi 전원, 펌프·LED 어댑터, ESP32 USB 모두).
> - 펌프와 LED는 **별도 어댑터**로 구동합니다. Pi의 5V 핀으로 모터를 돌리지 않습니다(전압 강하로 Pi가 재부팅되거나 손상됩니다).
> - 220V 교류 조명은 이 가이드에서 다루지 않습니다. DC(5V/12V) LED만 사용합니다.
> - 펌프 1회 작동 시간은 소프트웨어에서 **최대 1초**로 제한되어 있습니다(Backend·Pi 양쪽).

---

## 0. 준비물

| 구분 | 부품 | 비고 |
|---|---|---|
| 제어 | Raspberry Pi 4 (Raspberry Pi OS Bookworm 64-bit), microSD 16GB 이상, 정품 5V 3A 어댑터 | 사용자 계정 이름은 `greenlink`로 만듭니다(경로가 `/home/greenlink/greenlink`로 고정). |
| 환경 센서 | DHT22(AM2302) 온습도 모듈 | 3핀 모듈 권장. 4핀 단품이면 10kΩ 저항 1개가 추가로 필요합니다. |
| 조도 센서 | BH1750(GY-302) 모듈 | I2C 주소 0x23 |
| 카메라 | Raspberry Pi Camera Module(v2/v3) + CSI 리본 케이블 | |
| 릴레이 | **2채널 5V 릴레이 모듈(Low 트리거, 옵토커플러, JD-VCC 점퍼 있는 제품)** | CH1 = 펌프, CH2 = LED |
| 급수 | DC 수중 펌프(5V 또는 12V) + 실리콘 호스 + 물통 | |
| 조명 | DC LED 식물등/스트립(5V 또는 12V) | |
| 부하 전원 | 펌프·LED 전압에 맞는 DC 어댑터(예: 12V 2A) + DC 잭 단자 | 펌프와 LED가 같은 전압이면 어댑터 하나를 같이 써도 됩니다. |
| 보호 | 1N4007 다이오드 1개 | 펌프 모터의 역기전력을 흡수합니다(권장). |
| 토양 센서 | ESP32 DevKit(esp32dev) + **정전용량식(capacitive) 토양수분 센서 v1.2** + USB 5V 어댑터 | 저항식 센서는 금방 부식되므로 권장하지 않습니다. |
| 기타 | 브레드보드 1개, 점퍼선(암-암, 암-수), 전선, 드라이버 | |

---

## 1. 핀 번호 한눈에 보기

### 1-1. Raspberry Pi 40핀 헤더 (사용하는 핀만)

Pi 4를 위에서 보고 **USB·이더넷 포트가 오른쪽**, 40핀 헤더가 위쪽 긴 변에 오게 놓습니다. 이때 헤더의 **아래 줄(보드 안쪽)이 홀수 핀**, **위 줄(보드 가장자리)이 짝수 핀**이고 **왼쪽 끝이 1·2번**입니다.
헷갈리면 Pi 터미널에서 `pinout` 명령으로 그림을 확인합니다.

```
   위 줄(짝수)   5V  5V  GND  -   -   -   GND  -   -
                [2] [4] [6] [8] [10][12][14][16][18]
                [1] [3] [5] [7] [9] [11][13][15][17]
   아래 줄(홀수) 3.3V SDA SCL GPIO4 GND  -  GPIO27 GPIO22 3.3V
                 ↑ 1번 핀 (USB 포트 반대쪽 끝)
```

| 물리 핀 | 이름 | 연결 대상 |
|---|---|---|
| **1** | 3.3V | 브레드보드 **3.3V 레일** (DHT22, BH1750, 릴레이 입력측 VCC) |
| **2** | 5V | 릴레이 모듈 **JD-VCC** (릴레이 코일 전원) |
| **3** | GPIO2 (SDA) | BH1750 **SDA** |
| **5** | GPIO3 (SCL) | BH1750 **SCL** |
| **6** | GND | 브레드보드 **GND 레일** |
| **7** | GPIO4 | DHT22 **DATA** |
| **13** | GPIO27 | 릴레이 **IN2** → LED |
| **15** | GPIO22 | 릴레이 **IN1** → 펌프 |

> 코드 기준값: `DHT_GPIO = 4`, `BH1750_ADDR = 0x23`, `RELAY_LED_GPIO = 27`, `RELAY_PUMP_GPIO = 22`(환경변수 `GREENLINK_PUMP_GPIO`), `RELAY_ACTIVE_HIGH = False`(Low 트리거).
> 펌프 핀을 바꾸면 `greenlink.env`의 `GREENLINK_PUMP_GPIO`, Backend 펌프 채널의 `gpioPin`, 아래 2-3의 `config.txt` 줄을 **모두** 같은 값으로 바꿔야 합니다.

### 1-2. ESP32 DevKit

| ESP32 핀(보드 인쇄) | 연결 대상 |
|---|---|
| **3V3** | 토양 센서 **VCC** |
| **GND** | 토양 센서 **GND** |
| **GPIO34** (보드에 `34` 또는 `D34`, `VP/VN` 옆) | 토양 센서 **AOUT** |

> GPIO34는 입력 전용 ADC1 핀이라 Wi-Fi를 켜도 아날로그 값을 읽을 수 있습니다. ADC2 핀(GPIO 0, 2, 4, 12~15, 25~27)은 Wi-Fi 사용 중에 읽히지 않으므로 쓰지 마세요.

---

## 2. 서버·앱 쪽 준비 (배선 전에 1번만)

장치 키와 식물 연결이 먼저 있어야 Pi와 ESP가 데이터를 올릴 수 있습니다.

1. **앱에서 식물 심기**: 앱으로 실제 사용할 계정에 가입하고 기본 지급된 바질 씨앗을 심습니다.
2. **userPlantId 확인**: 관리자 대시보드(`https://greenlink.likepigs.shop/admin`)의 최근 명령이나 식물 상세에서 확인합니다.
3. **장치 등록과 설정 파일 생성** (맥, 저장소 루트):
   ```bash
   python3 scripts/setup_iot.py --user-plant-id <userPlantId>
   ```
   - 재배 공간 `greenlink-grower-1`, 장치 `greenlink-pi`와 `greenlink-esp`, 펌프 채널(GPIO 22, 릴레이 1번)을 등록합니다.
   - `greenlink_pi/greenlink.env`와 `greenlink_esp/secrets.ini`를 만듭니다. 두 파일 모두 커밋하면 안 됩니다.
4. 이후 앱에서 식물을 **수확하고 새 씨앗을 심으면** 서버가 재배기(ESP 센서·펌프·사진·자동화 설정)를 새 식물로 자동으로 옮깁니다. 배선이나 설정 파일은 다시 만들 필요가 없습니다.

---

## 3. Raspberry Pi 기본 설정 (전원만 연결, 배선은 아직 안 함)

### 3-1. OS 설치
Raspberry Pi Imager로 **Raspberry Pi OS (64-bit, Bookworm)** 를 굽습니다. 고급 설정에서 다음을 지정합니다.
- 호스트 이름 `greenlink-pi`
- 사용자 `greenlink`
- Wi-Fi
- SSH 사용

### 3-2. I2C와 카메라 켜기
```bash
sudo raspi-config nonint do_i2c 0
sudo apt update
sudo apt install -y python3-picamera2 python3-smbus python3-gpiozero python3-lgpio i2c-tools python3-venv
```
Bookworm은 카메라가 기본으로 켜져 있습니다(libcamera).

### 3-3. ⚠️ 부팅 순간에도 펌프가 켜지지 않게 고정 (중요)
GPIO22와 27은 Pi가 부팅될 때 기본값이 **LOW(풀다운)** 입니다. Low 트리거 릴레이는 LOW에서 **켜지기** 때문에, 그냥 두면 Pi를 켤 때마다 명령 워커가 뜨기 전 몇 초 동안 **펌프가 돌 수 있습니다**.
펌웨어 단계에서 두 핀을 처음부터 HIGH(=릴레이 꺼짐)로 고정합니다.

```bash
echo 'gpio=22,27=op,dh' | sudo tee -a /boot/firmware/config.txt
sudo reboot
```
- `op` = 출력, `dh` = HIGH로 구동
- High 트리거 릴레이를 쓰면 `dh` 대신 `dl`로 바꾸고, `greenlink_pi/config.py`의 `RELAY_ACTIVE_HIGH = True`로 바꿉니다.

---

## 4. 배선 — 전원을 모두 뽑은 상태에서 순서대로

### 4-1. 브레드보드 전원 레일 만들기
| 점퍼선 | 브레드보드 |
|---|---|
| Pi **1번**(3.3V) | 빨간(+) 레일 → 이후 "3.3V 레일" |
| Pi **6번**(GND) | 파란(−) 레일 → 이후 "GND 레일" |

### 4-2. DHT22 온습도 센서
**3핀 모듈**(`+`, `out`, `-` 표기):

| DHT22 모듈 | 연결 |
|---|---|
| `+` (VCC) | 3.3V 레일 |
| `out` (DATA) | Pi **7번**(GPIO4) |
| `-` (GND) | GND 레일 |

**4핀 단품**(구멍 난 면을 보고 왼쪽부터 1~4번):
- 1번 VCC → 3.3V 레일
- 2번 DATA → Pi 7번
- 3번 → 연결하지 않음
- 4번 GND → GND 레일
- **10kΩ 저항을 1번(VCC)과 2번(DATA) 사이에 연결합니다.**

> 센서는 LED 바로 아래나 물 튀는 곳을 피해 재배기 공기 중간 높이에 둡니다.

### 4-3. BH1750 조도 센서 (GY-302)
| BH1750 | 연결 |
|---|---|
| VCC | 3.3V 레일 |
| GND | GND 레일 |
| SCL | Pi **5번**(GPIO3) |
| SDA | Pi **3번**(GPIO2) |
| ADDR | GND 레일 (또는 비워 둠, 주소 0x23) |

> 조도 센서가 LED 빛을 직접 받으면 LED가 켜진 동안 측정값이 크게 올라갑니다.
> 서버의 자동 조명은 **LED가 켜진 동안에는 조도로 끄지 않고 작동 시간대가 끝날 때 끄도록** 되어 있어 깜빡임은 생기지 않습니다.
> 다만 자연광을 정확히 재려면 센서를 LED를 등지게 두거나 재배기 옆면에 붙이는 것이 좋습니다.

### 4-4. 릴레이 모듈 (신호 쪽)
JD-VCC 점퍼가 있는 2채널 모듈 기준입니다. **노란 점퍼(JD-VCC↔VCC)를 뽑습니다.** 그러면 입력측(옵토커플러)은 3.3V, 코일은 5V로 분리됩니다.

| 릴레이 모듈 핀 | 연결 | 역할 |
|---|---|---|
| **VCC** (입력측 핀 줄) | 3.3V 레일 | 옵토커플러 전원. Pi 3.3V 신호로 확실히 꺼지게 합니다. |
| **GND** | GND 레일 | |
| **IN1** | Pi **15번**(GPIO22) | 펌프 |
| **IN2** | Pi **13번**(GPIO27) | LED |
| **JD-VCC** (점퍼 쪽 핀) | Pi **2번**(5V) | 릴레이 코일 전원 |
| 점퍼 옆 **GND** | GND 레일 | 코일 GND(모듈에 따라 공용) |

> 점퍼가 없는 저가 모듈은 VCC를 5V(Pi 2번)에 연결합니다. 이 경우 Pi의 3.3V HIGH로 릴레이가 **완전히 꺼지지 않는** 제품이 있습니다.
> 아래 6단계 점검에서 "꺼짐"인데 릴레이 LED가 희미하게 켜져 있거나 딸깍거리면, JD-VCC 점퍼가 있는 모듈이나 3.3V 트리거 모듈로 교체합니다.

### 4-5. 카메라
1. Pi 전원이 꺼진 상태에서 CSI 커넥터(`CAMERA` 표기)의 검은 걸쇠를 위로 살짝 들어 올립니다.
2. 리본 케이블을 끝까지 꽂습니다.
   - Pi 4: **금속 접점이 HDMI 포트 쪽**, 파란 면이 USB·이더넷 쪽을 보게 꽂습니다.
3. 걸쇠를 눌러 잠급니다.
4. 카메라를 재배기 위에 식물 전체가 보이게 고정합니다.
   - 코드는 `ROTATE_180 = True`(거꾸로 단 카메라 기준)입니다.
   - 화면이 뒤집혀 나오면 `greenlink_pi/stream_server.py`의 `ROTATE_180`을 `False`로 바꿉니다.

### 4-6. 펌프와 LED (부하 쪽) — 5·6단계 점검 후 연결 권장
릴레이 각 채널의 출력 단자는 **COM**(공통), **NO**(평상시 열림), **NC**(평상시 닫힘) 세 개입니다. **반드시 NO를 씁니다.** 그래야 Pi가 꺼지거나 신호가 끊겼을 때 펌프와 LED가 꺼진 상태로 남습니다.

**펌프 (CH1)**
```
DC 어댑터 (+) ──── CH1 COM
                    CH1 NO ──── 펌프 (+, 빨간선)
DC 어댑터 (−) ─────────────────── 펌프 (−, 검은선)
```
1N4007 다이오드는 펌프 단자에 **띠(캐소드)가 펌프 (+) 쪽**으로 가게 병렬로 연결합니다.

**LED (CH2)**
```
DC 어댑터 (+) ──── CH2 COM
                    CH2 NO ──── LED (+)
DC 어댑터 (−) ─────────────────── LED (−)
```

> 부하용 어댑터의 (−)는 Pi GND와 **연결하지 않아도 됩니다**. 릴레이 접점이 전기적으로 분리해 줍니다.
> 펌프 호스 끝은 화분 흙 위에 고정하고, 물통 수위가 펌프보다 높게 유지되도록 합니다.
> 펌프가 물 없이 돌면(공회전) 고장 납니다.

---

## 5. Pi 소프트웨어 설치

맥에서 저장소 루트 기준으로 코드를 Pi로 복사합니다.
```bash
rsync -av --exclude tests --exclude __pycache__ greenlink_pi/ greenlink@greenlink-pi.local:/home/greenlink/greenlink/
```

Pi에서 실행합니다.
```bash
cd /home/greenlink/greenlink
python3 -m venv --system-site-packages .venv
.venv/bin/pip install -r requirements.txt
chmod 600 greenlink.env
chmod +x run_sensor.sh run_camera.sh run_command.sh
```

---

## 6. 단계별 점검 — 하나씩 확인한 뒤 다음으로

모든 명령은 Pi의 `/home/greenlink/greenlink`에서 실행합니다. 환경변수를 먼저 불러옵니다.
```bash
set -a; . ./greenlink.env; set +a
```

### 6-1. I2C 조도 센서
```bash
i2cdetect -y 1
```
표에 `23`이 보이면 정상입니다. 보이지 않으면 SDA와 SCL이 서로 바뀌었는지, VCC와 GND가 맞는지 확인합니다.

### 6-2. 온습도와 조도 측정
```bash
.venv/bin/python3 sensor_service.py
```
`lightLux`, `temperatureC`, `humidityPercent`가 숫자로 나오면 정상입니다.
`temperatureC=None`이면 DHT22의 DATA 핀(7번)과 4핀 단품의 10kΩ 저항을 확인합니다.

### 6-3. 릴레이 (펌프·LED 부하는 아직 연결하지 않은 상태)
```bash
.venv/bin/python3 relay_control.py
```
1. 시작하자마자 "전체 OFF"가 됩니다. **릴레이 LED 2개가 모두 꺼져 있어야 합니다.**
2. 엔터를 누르면 CH2(LED)가 2초 "딸깍" 켜졌다 꺼집니다.
3. 다시 엔터를 누르면 CH1(펌프)이 1초 켜졌다 꺼집니다.
4. 반대 채널이 움직이면 IN1과 IN2 배선을 바꿉니다.

이 점검이 끝나면 전원을 끄고 4-6대로 펌프와 LED를 연결한 뒤, 같은 명령으로 실제 동작을 확인합니다.

### 6-4. 서버 업로드
```bash
./run_sensor.sh && tail -5 sensor.log
```
`센서 업로드 성공`이 보이면, 관리자 대시보드의 `greenlink-pi`가 "온라인"으로 바뀝니다.

### 6-5. 상시 서비스와 주기 작업 등록
```bash
sudo cp systemd/greenlink-command.service systemd/greenlink-stream.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now greenlink-command greenlink-stream
systemctl status greenlink-command greenlink-stream --no-pager
crontab crontab.example        # 센서 10분마다, 썸네일 매일 09:00
sudo cp logrotate.conf /etc/logrotate.d/greenlink   # *.log가 SD카드를 채우지 않게 주간 정리
```
- 로그 보기: `journalctl -u greenlink-command -f`
- 브라우저에서 `http://greenlink-pi.local:8000/`를 열어 카메라 영상이 나오는지 확인합니다.
- 썸네일 업로드는 기다리지 말고 바로 시험합니다: `./run_camera.sh && tail -5 camera.log`

### 6-6. 앱에서 보이는 카메라 주소 (Cloudflare 터널)
앱의 기본 카메라 주소는 `https://greenlink-camera.likepigs.shop`입니다. Pi에 cloudflared를 설치하고 이 주소를 `http://localhost:8000`으로 연결합니다.
```bash
# cloudflared 설치 후
cloudflared tunnel login
cloudflared tunnel create greenlink-camera
cloudflared tunnel route dns greenlink-camera greenlink-camera.likepigs.shop
# ~/.cloudflared/config.yml 의 ingress: hostname greenlink-camera.likepigs.shop → service http://localhost:8000
sudo cloudflared service install
```
영상에는 인증이 없습니다. 공개 범위를 Cloudflare Access 등으로 제한하는 것을 권장합니다.

---

## 7. ESP32 토양 센서

### 7-1. 배선 (USB를 뽑은 상태)
| 토양 센서 v1.2 | ESP32 |
|---|---|
| VCC (빨강) | **3V3** |
| GND (검정) | **GND** |
| AOUT (노랑) | **GPIO34** |

센서를 흙에 꽂을 때는 기판의 **흰 선(표시선)까지만** 넣습니다. 그 위의 전자부품 부분이 젖으면 고장 납니다.

### 7-2. 보정값 측정 (DRY_RAW / WET_RAW)
1. `greenlink_esp/secrets.ini`(setup_iot.py가 생성)에 Wi-Fi SSID와 비밀번호를 채웁니다.
2. 처음에는 보정값을 임시값 그대로(`DRY_RAW=1700`, `WET_RAW=1300`) 두고 업로드합니다.
   ```bash
   cd greenlink_esp
   pio run -t upload
   pio device monitor        # 115200
   ```
3. 시리얼 모니터에 찍히는 `[RAW 평균]`을 기록합니다.
   - **마른 흙**에 꽂았을 때의 값 → `GREENLINK_DRY_RAW`
   - **물을 충분히 준 흙**에 꽂았을 때의 값 → `GREENLINK_WET_RAW`
   - 마른 흙 값이 젖은 흙 값보다 **커야** 합니다.
4. 값을 `secrets.ini`에 넣고 다시 `pio run -t upload`합니다.
5. 측정값 확인
   - 첫 측정은 켜자마자 1번 보내고, 이후 10분마다 보냅니다.
   - 시리얼에 `[서버 전송 성공]`이 뜨면 앱 IoT 화면의 토양 수분에 값이 나옵니다.
   - 센서를 흙에서 빼면 `[전송 생략]`이 나오고 값을 보내지 않습니다. 이것이 정상 동작입니다(0%가 올라가 자동 급수가 반복되는 것을 막음).

### 7-3. 설치
ESP32를 USB 5V 어댑터에 연결해 재배기 옆 물이 닿지 않는 곳에 고정합니다.

---

## 8. 전체 흐름 최종 점검표

| # | 확인 | 방법 | 기대 결과 |
|---|---|---|---|
| 1 | 환경 센서 | 앱 → 식물 상세 → IoT 상태 → **센서 새로고침** | 몇 초 안에 온도·습도·조도가 갱신되고, 최근 명령에 "센서 새로고침 · 완료" |
| 2 | 토양 센서 | 같은 화면 토양 수분 카드 | ESP 측정값(%)과 측정 시각 |
| 3 | 수동 급수 | **물 주기** 버튼 | 펌프가 약 1초 작동하고, 최근 명령이 "물 주기 · 완료"로 바뀜(최대 약 30초 안에 자동 갱신) |
| 4 | 조명 | **조명 켜기 / 끄기** | LED가 켜지고 꺼지며, 조명 상태 칩이 바뀜 |
| 5 | 카메라 | IoT 화면 상단 실시간 영상 | 재배기 전체 화면 |
| 6 | 그래프 | 센서 기록 카드 24시간 / 7일 | 10분 간격 점 |
| 7 | 썸네일 | `./run_camera.sh` 실행 후 앱 홈 | 카드 이미지가 오늘 찍은 사진으로 바뀌고 촬영 날짜가 표시됨 |
| 8 | 자동 급수 | 식물 상세 → 자동화 관리 → 자동 물 주기 ON, 저장 | 토양 수분이 기준(기본 35%) 이하가 되면 다음 ESP 측정 때 1초 급수. 쿨다운 30분 |
| 9 | 자동 조명 | 자동 조명 ON(작동 시간 08~18시) | 어두우면 켜지고, 시간대가 끝나면 꺼짐. 꺼진 상태에서는 OFF를 반복해서 보내지 않음 |
| 10 | 관리자 | `/admin` 대시보드 | `greenlink-pi`, `greenlink-esp` 모두 온라인, 24시간 실패 명령 0 |
| 11 | 재부팅 | `sudo reboot` | 부팅 중 펌프·LED가 켜지지 않고, 서비스가 자동으로 다시 뜸 |
| 12 | Pi 오프라인 복귀 | 명령 워커를 5분 넘게 멈춘 동안 앱에서 물 주기를 누른 뒤 워커 재시작 | 지난 명령은 실행되지 않고 "자동으로 취소" 처리됨 |

---

## 9. 자주 생기는 문제

| 증상 | 원인 / 해결 |
|---|---|
| Pi를 켤 때 펌프가 잠깐 돈다 | 3-3의 `gpio=22,27=op,dh` 줄이 없거나 핀 번호가 다릅니다. |
| "꺼짐"인데 릴레이 LED가 희미하게 켜짐 | 5V 입력 릴레이를 3.3V 신호로 쓰는 경우입니다. 4-4대로 JD-VCC 점퍼를 분리하고 VCC를 3.3V에 연결하거나 모듈을 바꿉니다. |
| 물 주기 명령이 "실패: 등록되지 않은 펌프 GPIO" | Backend 펌프 채널의 `gpioPin`과 `GREENLINK_PUMP_GPIO`가 다릅니다. |
| 물 주기 버튼이 비활성 / "수분 충분" | 급수 보호모드가 켜져 있고 토양 수분이 기준+10% 이상입니다. 정상 동작입니다. |
| 명령이 계속 "대기"로 남음 | `systemctl status greenlink-command`를 확인합니다. 5분이 지나면 자동 취소됩니다. |
| `i2cdetect`에 23이 안 보임 | I2C가 꺼져 있거나(3-2) SDA·SCL 배선이 바뀌었습니다. |
| 온습도가 None | DHT22 DATA는 GPIO4(물리 7번)입니다. 4핀 단품이면 10kΩ 풀업 저항이 필요합니다. |
| 토양 수분이 항상 0% 또는 100% | `DRY_RAW`/`WET_RAW` 보정값이 실제 흙과 맞지 않습니다. 7-2를 다시 측정합니다. |
| ESP 시리얼에 `[전송 생략]`만 나옴 | 센서가 흙에서 빠졌거나 AOUT이 GPIO34가 아닌 핀에 꽂혀 있습니다. |
| 앱 카메라가 "불러올 수 없습니다" | `greenlink-stream` 서비스 상태와 Cloudflare 터널 주소를 확인합니다(6-6). |
| 수확 후 새 식물에 센서값이 안 보임 | 새 씨앗을 **같은 계정**으로 심어야 자동으로 옮겨집니다. 다른 계정이면 `setup_iot.py --user-plant-id <새 ID>`로 교체합니다. |

# Pi 전역 설정 — 서버 URL, GPIO 핀, 센서, 카메라, 식물 매핑

import os
from pathlib import Path


# 서버 주소와 장치 키는 소스에 두지 않고 환경변수로 주입한다.
# 값이 없으면 스크립트가 시작 시점에 실패한다. greenlink.env.example 참고.
def _require_env(name: str) -> str:
    value = os.environ.get(name, "")

    if not value:
        raise RuntimeError(f"{name} 환경변수가 없습니다. greenlink.env를 확인하세요.")

    return value


# 서버 설정

BASE_URL = _require_env("GREENLINK_BASE_URL")
DEVICE_KEY = _require_env("GREENLINK_DEVICE_KEY")

SERVER_ENVIRONMENT_URL = f"{BASE_URL}/api/iot/raspberry/environment"
SERVER_IMAGE_URL = f"{BASE_URL}/api/iot/plant-images"
SERVER_PENDING_COMMAND_URL = f"{BASE_URL}/api/iot/commands/pending"



# 식물 ID 설정
# Backend DB의 userPlantId와 반드시 일치해야 한다.
# 값이 틀리면 다른 식물에 사진이 업로드되므로 소스에 고정하지 않고 환경변수로 주입한다.

# 재배기 한 대에 식물 한 개를 기준으로 운영한다.
USER_PLANT_ID = int(_require_env("GREENLINK_USER_PLANT_ID"))


# 파일/이미지 저장 설정

BASE_DIR = Path("/home/greenlink/greenlink")
IMAGE_DIR = BASE_DIR / "images"
IMAGE_DIR.mkdir(parents=True, exist_ok=True)


# 실시간 스트림 스냅샷 설정
# 아침 자동 촬영은 카메라를 새로 열지 않고,
# greenlink-stream의 전체 원본 스트림에서 JPEG 1장을 가져온다.
# 식물 한 개 기준이므로 crop 없이 전체 프레임을 그대로 업로드한다.

LOCAL_STREAM_BASE_URL = "http://127.0.0.1:8000"

# 전체 원본 스트림
FULL_STREAM_URL = f"{LOCAL_STREAM_BASE_URL}/stream.mjpg"


# 릴레이 GPIO 설정
# GPIO27 → LED
# 펌프 → GREENLINK_PUMP_GPIO (기본 22). 배선을 바꾸면 환경변수만 수정한다.
# Backend PumpChannel의 gpioPin도 같은 값이어야 명령이 실행된다.

RELAY_LED_GPIO = 27
RELAY_PUMP_GPIO = int(os.environ.get("GREENLINK_PUMP_GPIO", "22"))

if RELAY_PUMP_GPIO == RELAY_LED_GPIO:
    raise RuntimeError("GREENLINK_PUMP_GPIO는 LED 릴레이 GPIO와 달라야 합니다.")

# 릴레이 모듈이 active LOW 방식이면 False
RELAY_ACTIVE_HIGH = False


# 센서 설정

DHT_GPIO = 4

BH1750_I2C_BUS = 1
BH1750_ADDR = 0x23


# 실행 주기 설정

SENSOR_INTERVAL_SECONDS = 600
COMMAND_POLL_INTERVAL_SECONDS = 3

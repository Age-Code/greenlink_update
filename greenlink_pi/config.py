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

# AI Worker 서버
AI_WORKER_URL = _require_env("GREENLINK_AI_WORKER_URL")

# AI Worker /process 인증용 공유 secret — Worker의 AI_PROCESS_SECRET과 동일해야 한다.
AI_PROCESS_SECRET = _require_env("GREENLINK_AI_PROCESS_SECRET")


# 식물 ID 설정
# Backend DB의 userPlantId와 반드시 일치해야 한다.
# 값이 틀리면 다른 식물에 사진이 업로드되므로 소스에 고정하지 않고 환경변수로 주입한다.

SUNFLOWER_USER_PLANT_ID = int(_require_env("GREENLINK_SUNFLOWER_USER_PLANT_ID"))
BASIL_USER_PLANT_ID = int(_require_env("GREENLINK_BASIL_USER_PLANT_ID"))

# 기존 코드 호환용
TOMATO_USER_PLANT_ID = SUNFLOWER_USER_PLANT_ID


# 파일/이미지 저장 설정

BASE_DIR = Path("/home/greenlink/greenlink")
IMAGE_DIR = BASE_DIR / "images"
IMAGE_DIR.mkdir(parents=True, exist_ok=True)


# 실시간 스트림 스냅샷 설정
# 아침 자동 촬영은 카메라를 새로 열지 않고,
# greenlink-stream의 전체 원본 스트림에서 JPEG 1장을 가져온다.
# 그 이미지 하나를 해바라기/바질 영역으로 crop해서 각각 업로드한다.

LOCAL_STREAM_BASE_URL = "http://127.0.0.1:8000"

# 전체 원본 스트림
FULL_STREAM_URL = f"{LOCAL_STREAM_BASE_URL}/stream.mjpg"

# stream_server.py와 동일한 crop 기준
# 현재 기준:
# 해바라기 = 오른쪽 절반
# 바질     = 왼쪽 절반
# 만약 실제 업로드 결과가 반대로 나오면 두 값을 서로 바꾸면 된다.
SUNFLOWER_CROP = (0.5, 0.0, 1.0, 1.0)
BASIL_CROP = (0.0, 0.0, 0.5, 1.0)

# crop 결과 저장 크기
SNAPSHOT_OUTPUT_WIDTH = 1080
SNAPSHOT_OUTPUT_HEIGHT = 1620


# 카메라 이미지 방향 보정
# 주의:
# 현재 아침 스냅샷은 /stream.mjpg에서 가져오므로,
# stream_server.py에서 이미 180도 회전이 적용된 화면을 받는다.
# 따라서 camera_main.py에서는 별도 회전 처리를 하지 않는다.
# 아래 값은 기존 camera_service.py 직접 촬영 코드와의 호환용이다.

IMAGE_ROTATE_DEGREES = 180
IMAGE_FLIP_LEFT_RIGHT = False


# 릴레이 GPIO 설정
# 정상 작동했던 기존 배선 기준:
# GPIO27 → LED
# GPIO22 → 바질 펌프
# GPIO23 → 해바라기 펌프

RELAY_LED_GPIO = 27
RELAY_BASIL_PUMP_GPIO = 22
RELAY_SUNFLOWER_PUMP_GPIO = 23

# 기존 코드 호환용
RELAY_TOMATO_PUMP_GPIO = RELAY_SUNFLOWER_PUMP_GPIO

# 릴레이 모듈이 active LOW 방식이면 False
RELAY_ACTIVE_HIGH = False


# 센서 설정

DHT_GPIO = 4

BH1750_I2C_BUS = 1
BH1750_ADDR = 0x23


# 실행 주기 설정

SENSOR_INTERVAL_SECONDS = 600
COMMAND_POLL_INTERVAL_SECONDS = 3

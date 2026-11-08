#!/usr/bin/env python3
"""GreenLink IoT 초기 구성 — 재배 공간·장치·펌프 등록과 장치 설정 파일 생성.

재배기 1대 = 식물 1개 구성을 백엔드에 등록하고, 같은 값으로
Raspberry Pi / ESP32 설정 파일을 만든다. 표준 라이브러리만 사용한다.

사용법 (저장소 루트에서):
    python3 scripts/setup_iot.py --user-plant-id 3

- 관리자 계정은 루트 .env의 GREENLINK_BOOTSTRAP_ADMIN_EMAIL/PASSWORD를 읽거나
  GREENLINK_ADMIN_EMAIL/GREENLINK_ADMIN_PASSWORD 환경변수로 넘긴다.
- 생성 파일(모두 .gitignore 대상): greenlink_pi/greenlink.env, greenlink_esp/secrets.ini
- 이미 있는 재배 공간·장치는 이름으로 찾아 재사용하므로 여러 번 실행해도 중복 등록되지 않는다.
  장치 키는 처음 등록할 때만 만들어지므로, 기존 장치를 재사용하면 설정 파일을 건드리지 않는다.
"""

import argparse
import json
import os
import secrets
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PI_DEVICE_NAME = "greenlink-pi"
ESP_DEVICE_NAME = "greenlink-esp"
PUMP_CHANNEL_NAME = "pump-1"


def read_dotenv(path: Path) -> dict:
    values = {}
    if not path.exists():
        return values
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


class Api:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.token = None

    def call(self, method: str, path: str, body=None):
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(self.base_url + path, data=data, method=method)
        request.add_header("Content-Type", "application/json")
        if self.token:
            request.add_header("Authorization", f"Bearer {self.token}")
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                payload = json.loads(response.read() or b"{}")
        except urllib.error.HTTPError as error:
            detail = error.read().decode(errors="replace")[:300]
            raise SystemExit(f"[ERROR] {method} {path} -> {error.code}: {detail}")
        if payload.get("success") is False:
            raise SystemExit(f"[ERROR] {method} {path}: {payload.get('message')}")
        return payload.get("data")


def write_private(path: Path, content: str, overwrite: bool):
    if path.exists() and not overwrite:
        print(f"[SKIP] {path.relative_to(ROOT)} 이미 있음")
        return
    path.write_text(content)
    path.chmod(0o600)
    print(f"[WRITE] {path.relative_to(ROOT)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default="https://greenlink.likepigs.shop")
    parser.add_argument("--user-plant-id", type=int, required=True, help="재배기에서 키울 사용자 식물 ID")
    parser.add_argument("--grow-space-name", default="greenlink-grower-1")
    parser.add_argument("--pump-gpio", type=int, default=22)
    args = parser.parse_args()

    root_env = read_dotenv(ROOT / ".env")
    email = os.environ.get("GREENLINK_ADMIN_EMAIL") or root_env.get("GREENLINK_BOOTSTRAP_ADMIN_EMAIL")
    password = os.environ.get("GREENLINK_ADMIN_PASSWORD") or root_env.get("GREENLINK_BOOTSTRAP_ADMIN_PASSWORD")
    if not email or not password:
        sys.exit("관리자 이메일/비밀번호가 없습니다. .env 또는 GREENLINK_ADMIN_* 환경변수를 확인하세요.")

    api = Api(args.base_url + "/api")
    api.token = api.call("POST", "/auth/login", {"email": email, "password": password})["accessToken"]
    print("[OK] 관리자 로그인")

    # 1) 재배 공간
    spaces = api.call("GET", "/iot/grow-spaces") or []
    space = next((s for s in spaces if s.get("name") == args.grow_space_name), None)
    if space is None:
        space = api.call("POST", "/iot/grow-spaces", {"name": args.grow_space_name, "description": "재배기 1대"})
        print(f"[CREATE] 재배 공간 {args.grow_space_name} (id={space['growSpaceId']})")
    else:
        print(f"[REUSE] 재배 공간 {args.grow_space_name} (id={space['growSpaceId']})")
    grow_space_id = space["growSpaceId"]

    # 2) 식물 연결 — 재배기 1대 = 식물 1개. 다른 식물이 연결돼 있으면 새 식물로 교체(replant)한다.
    connected = api.call("GET", f"/iot/grow-spaces/{grow_space_id}/plants") or []
    if any(p.get("userPlantId") == args.user_plant_id for p in connected):
        print(f"[REUSE] 식물 {args.user_plant_id} 이미 연결됨")
    elif connected:
        api.call("POST", f"/iot/grow-spaces/{grow_space_id}/replant", {"userPlantId": args.user_plant_id})
        print(f"[REPLANT] 재배기를 식물 {args.user_plant_id}로 교체 (ESP 센서·펌프 채널도 함께 이동)")
    else:
        api.call("POST", f"/iot/grow-spaces/{grow_space_id}/plants", {"userPlantId": args.user_plant_id})
        print(f"[CREATE] 식물 {args.user_plant_id} 연결")

    # 3) 장치 — 새로 만들 때만 키를 생성한다
    devices = api.call("GET", "/iot/devices") or []
    device_keys = {}

    def ensure_device(name, device_type, extra):
        existing = next((d for d in devices if d.get("deviceName") == name), None)
        if existing:
            print(f"[REUSE] 장치 {name} (id={existing['deviceId']}) — 키는 기존 설정 파일 값을 사용")
            return existing["deviceId"]
        key = secrets.token_hex(24)
        created = api.call("POST", "/iot/devices", {"deviceName": name, "deviceType": device_type, "deviceKey": key, **extra})
        device_keys[name] = key
        print(f"[CREATE] 장치 {name} (id={created['deviceId']})")
        return created["deviceId"]

    pi_id = ensure_device(PI_DEVICE_NAME, "RASPBERRY_PI", {"growSpaceId": grow_space_id})
    ensure_device(ESP_DEVICE_NAME, "ESP32", {"growSpaceId": grow_space_id, "userPlantId": args.user_plant_id})

    # 4) 펌프 채널 — 재배 공간에 이미 펌프가 있으면 재사용한다(replant 때 새 식물로 이미 옮겨짐).
    channels = api.call("GET", "/iot/pump-channels") or []
    if any(c.get("userPlantId") == args.user_plant_id or c.get("growSpaceId") == grow_space_id for c in channels):
        print(f"[REUSE] 재배 공간 {args.grow_space_name} 펌프 채널 이미 있음")
    else:
        api.call("POST", "/iot/pump-channels", {
            "growSpaceId": grow_space_id,
            "userPlantId": args.user_plant_id,
            "raspberryDeviceId": pi_id,
            "channelName": PUMP_CHANNEL_NAME,
            "gpioPin": args.pump_gpio,
            "relayChannel": 1,
        })
        print(f"[CREATE] 펌프 채널 GPIO {args.pump_gpio}")

    # 5) 설정 파일 — 새 키를 만든 장치의 파일만 쓴다
    pi_key = device_keys.get(PI_DEVICE_NAME)
    esp_key = device_keys.get(ESP_DEVICE_NAME)

    if pi_key:
        write_private(ROOT / "greenlink_pi" / "greenlink.env", "\n".join([
            "# setup_iot.py가 생성 — 커밋 금지",
            f"GREENLINK_BASE_URL={args.base_url}",
            f"GREENLINK_DEVICE_KEY={pi_key}",
            "# 사진은 Backend가 이 재배기의 현재 식물에 붙인다. 수확 후 새로 심어도 고칠 필요 없음",
            f"GREENLINK_PUMP_GPIO={args.pump_gpio}",
            "",
        ]), True)
    if esp_key:
        write_private(ROOT / "greenlink_esp" / "secrets.ini", "\n".join([
            "; setup_iot.py가 생성 — 커밋 금지. Wi-Fi와 보정값을 채운 뒤 빌드한다.",
            "[secrets]",
            "build_flags =",
            "    -D GREENLINK_WIFI_SSID='\"<wifi-ssid>\"'",
            "    -D GREENLINK_WIFI_PASSWORD='\"<wifi-password>\"'",
            f"    -D GREENLINK_SERVER_URL='\"{args.base_url}/api/iot/esp/soil-moisture\"'",
            f"    -D GREENLINK_DEVICE_KEY='\"{esp_key}\"'",
            "    -D GREENLINK_DRY_RAW=1700",
            "    -D GREENLINK_WET_RAW=1300",
            "",
        ]), True)
    print("\n완료. 생성된 키는 위 파일에만 있고 화면에는 출력하지 않았습니다.")


if __name__ == "__main__":
    main()

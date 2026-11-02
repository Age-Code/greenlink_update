# 명령 API 클라이언트 — PENDING 조회, PROCESSING/SUCCESS/FAILED PATCH

import requests

from config import (
    SERVER_PENDING_COMMAND_URL,
    DEVICE_KEY,
    BASE_URL,
)


# 장치 인증 헤더 생성 — X-DEVICE-KEY 포함
def get_device_headers():
    return {
        "X-DEVICE-KEY": DEVICE_KEY
    }


# 대기 명령 조회 — Backend PENDING 명령 polling
def get_pending_commands():
    response = requests.get(
        SERVER_PENDING_COMMAND_URL,
        headers=get_device_headers(),
        timeout=10,
    )

    response.raise_for_status()

    body = response.json()

    if body.get("success") is not True:
        raise RuntimeError(body.get("message", "대기 명령 조회 실패"))

    return body.get("data", [])


# 명령 처리 시작 보고 — PROCESSING PATCH
def mark_command_processing(command_id: int):
    url = f"{BASE_URL}/api/iot/commands/{command_id}/processing"

    response = requests.patch(
        url,
        headers=get_device_headers(),
        timeout=10,
    )

    response.raise_for_status()

    body = response.json()

    if body.get("success") is not True:
        raise RuntimeError(body.get("message", "명령 처리 시작 보고 실패"))

    return body


# 명령 완료 보고 — SUCCESS/FAILED PATCH
def complete_command(command_id: int, success: bool, result_message: str):
    url = f"{BASE_URL}/api/iot/commands/{command_id}/complete"

    payload = {
        "success": success,
        "resultMessage": result_message,
    }

    response = requests.patch(
        url,
        headers={
            **get_device_headers(),
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=10,
    )

    response.raise_for_status()

    body = response.json()

    if body.get("success") is not True:
        raise RuntimeError(body.get("message", "명령 완료 보고 실패"))

    return body

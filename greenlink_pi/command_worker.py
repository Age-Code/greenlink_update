# 명령 워커 — 3초 polling 후 WATER/LIGHT/SENSOR_REFRESH 분기 실행

import signal
import time

from api_client import (
    get_pending_commands,
    mark_command_processing,
    complete_command,
)
from config import COMMAND_POLL_INTERVAL_SECONDS
from relay_control import pump_for_gpio, led_on, led_off, all_off
from sensor_service import read_all_sensors
from sensor_uploader import upload_sensor_data_safe
from water_duration import resolve_water_duration


# WATER 명령 처리 — 펌프 GPIO를 durationSeconds 동안 작동
def handle_water_command(command: dict):
    command_id = command.get("commandId")
    raw_duration_seconds = command.get("durationSeconds", "<missing>")

    pump_channel = command.get("pumpChannel") or {}
    gpio_pin = pump_channel.get("gpioPin")
    relay_channel = pump_channel.get("relayChannel")

    print("[COMMAND] WATER 명령 수신")
    print(f"[COMMAND] commandId = {command_id}")
    print(f"[COMMAND] gpioPin = {gpio_pin}")
    print(f"[COMMAND] relayChannel = {relay_channel}")
    print(f"[COMMAND] durationSeconds = {raw_duration_seconds}")

    if command_id is None:
        print("[COMMAND] commandId가 없어 명령을 처리할 수 없습니다.")
        return

    if gpio_pin is None:
        try:
            mark_command_processing(command_id)
            complete_command(
                command_id=command_id,
                success=False,
                result_message="gpioPin이 없어 급수 명령을 처리할 수 없습니다."
            )
        except Exception as e:
            print(f"[COMMAND] gpioPin 없음 실패 보고 중 오류: {e}")
        return

    try:
        mark_command_processing(command_id)
        print(f"[COMMAND] PROCESSING 보고 완료: commandId={command_id}")

        duration_seconds = resolve_water_duration(command)

        pump_for_gpio(
            gpio_pin=int(gpio_pin),
            seconds=duration_seconds
        )

        complete_command(
            command_id=command_id,
            success=True,
            result_message=f"급수 완료: GPIO {gpio_pin}, {duration_seconds}초"
        )

        print(f"[COMMAND] SUCCESS 보고 완료: commandId={command_id}")

    except Exception as e:
        print(f"[COMMAND] 급수 명령 처리 실패: {e}")

        try:
            complete_command(
                command_id=command_id,
                success=False,
                result_message=f"급수 실패: {e}"
            )
            print(f"[COMMAND] FAILED 보고 완료: commandId={command_id}")

        except Exception as report_error:
            print(f"[COMMAND] 실패 보고도 실패: {report_error}")

        all_off()


# LIGHT 명령 처리 — LIGHT_ON/LIGHT_OFF에 따라 LED 제어
def handle_light_command(command: dict):
    command_id = command.get("commandId")
    command_type = command.get("commandType")

    print("[COMMAND] 조명 명령 수신")
    print(f"[COMMAND] commandId = {command_id}")
    print(f"[COMMAND] commandType = {command_type}")

    if command_id is None:
        print("[COMMAND] commandId가 없어 조명 명령을 처리할 수 없습니다.")
        return

    try:
        mark_command_processing(command_id)
        print(f"[COMMAND] PROCESSING 보고 완료: commandId={command_id}")

        if command_type == "LIGHT_ON":
            led_on()
            result_message = "LED 조명 켜기 완료"

        elif command_type == "LIGHT_OFF":
            led_off()
            result_message = "LED 조명 끄기 완료"

        else:
            raise ValueError(f"지원하지 않는 조명 명령입니다: {command_type}")

        complete_command(
            command_id=command_id,
            success=True,
            result_message=result_message
        )

        print(f"[COMMAND] SUCCESS 보고 완료: commandId={command_id}")

    except Exception as e:
        print(f"[COMMAND] 조명 명령 처리 실패: {e}")

        try:
            complete_command(
                command_id=command_id,
                success=False,
                result_message=f"조명 명령 실패: {e}"
            )
            print(f"[COMMAND] FAILED 보고 완료: commandId={command_id}")

        except Exception as report_error:
            print(f"[COMMAND] 실패 보고도 실패: {report_error}")


# SENSOR_REFRESH 처리 — 온도/습도/조도 재측정 후 업로드
def handle_sensor_refresh_command(command: dict):
    command_id = command.get("commandId")

    print("[COMMAND] SENSOR_REFRESH 명령 수신")
    print(f"[COMMAND] commandId = {command_id}")
    print("[COMMAND] 새로고침 대상: 온도 / 습도 / 조도")
    print("[COMMAND] 제외 대상: ESP32 토양수분")

    if command_id is None:
        print("[COMMAND] commandId가 없어 센서 새로고침 명령을 처리할 수 없습니다.")
        return

    try:
        mark_command_processing(command_id)
        print(f"[SENSOR_REFRESH] PROCESSING 보고 완료: commandId={command_id}")

        print("[SENSOR_REFRESH] Raspberry Pi 센서 측정 시작")
        sensor_data = read_all_sensors()

        print(f"[SENSOR_REFRESH] lightLux = {sensor_data.get('lightLux')}")
        print(f"[SENSOR_REFRESH] temperatureC = {sensor_data.get('temperatureC')}")
        print(f"[SENSOR_REFRESH] humidityPercent = {sensor_data.get('humidityPercent')}")

        upload_success, upload_body = upload_sensor_data_safe(sensor_data)

        if not upload_success:
            raise RuntimeError(f"센서 업로드 실패: {upload_body}")

        complete_command(
            command_id=command_id,
            success=True,
            result_message="센서 새로고침 완료: 온도/습도/조도 업로드 성공"
        )

        print(f"[SENSOR_REFRESH] SUCCESS 보고 완료: commandId={command_id}")

    except Exception as e:
        print(f"[SENSOR_REFRESH] 센서 새로고침 처리 실패: {e}")

        try:
            complete_command(
                command_id=command_id,
                success=False,
                result_message=f"센서 새로고침 실패: {e}"
            )
            print(f"[SENSOR_REFRESH] FAILED 보고 완료: commandId={command_id}")

        except Exception as report_error:
            print(f"[SENSOR_REFRESH] 실패 보고도 실패: {report_error}")


# 명령 타입 분기 — WATER/LIGHT/SENSOR_REFRESH 처리
def handle_command(command: dict):
    command_type = command.get("commandType")

    if command_type == "WATER":
        handle_water_command(command)
        return

    if command_type in ("LIGHT_ON", "LIGHT_OFF"):
        handle_light_command(command)
        return

    if command_type == "SENSOR_REFRESH":
        handle_sensor_refresh_command(command)
        return

    print(f"[COMMAND] 지원하지 않는 명령 타입입니다: {command_type}")


# 명령 polling 1회 실행 — 대기 명령 순차 처리
def run_once():
    commands = get_pending_commands()

    if not commands:
        print("[COMMAND] 대기 중인 명령 없음")
        return

    print(f"[COMMAND] 대기 중인 명령 {len(commands)}개 발견")

    for command in commands:
        handle_command(command)


# 종료 시그널을 SystemExit로 바꿔 펌프 finally와 all_off가 실행되도록 한다.
def _exit_on_signal(signum, frame):
    print(f"[COMMAND] 종료 시그널 수신: {signum}")
    raise SystemExit(128 + signum)


# 명령 polling 루프 — 3초 주기로 Backend 조회
def run_forever():
    signal.signal(signal.SIGTERM, _exit_on_signal)
    signal.signal(signal.SIGHUP, _exit_on_signal)

    print("[COMMAND] 서버 명령 polling 시작")
    print("[COMMAND] 지원 명령: WATER, LIGHT_ON, LIGHT_OFF, SENSOR_REFRESH")

    try:
        while True:
            try:
                run_once()

            except Exception as e:
                print(f"[COMMAND] polling 오류: {e}")
                all_off()

            time.sleep(COMMAND_POLL_INTERVAL_SECONDS)

    finally:
        all_off()


if __name__ == "__main__":
    run_forever()

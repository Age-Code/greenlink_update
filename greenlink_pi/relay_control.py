# 릴레이 제어 — LED/펌프 GPIO on/off, active-low

from gpiozero import OutputDevice
from time import sleep

from config import (
    RELAY_LED_GPIO,
    RELAY_PUMP_GPIO,
    RELAY_ACTIVE_HIGH,
)


led_relay = OutputDevice(
    RELAY_LED_GPIO,
    active_high=RELAY_ACTIVE_HIGH,
    initial_value=False
)

pump_relay = OutputDevice(
    RELAY_PUMP_GPIO,
    active_high=RELAY_ACTIVE_HIGH,
    initial_value=False
)


# LED 릴레이 제어 — on/off 상태 적용
def set_led(on: bool):
    if on:
        print(f"[RELAY] LED ON: GPIO {RELAY_LED_GPIO}")
        led_relay.on()
    else:
        print(f"[RELAY] LED OFF: GPIO {RELAY_LED_GPIO}")
        led_relay.off()


# 펌프 릴레이 제어 — on/off 상태 적용
def set_pump(on: bool):
    if on:
        print(f"[RELAY] 펌프 ON: GPIO {RELAY_PUMP_GPIO}")
        pump_relay.on()
    else:
        print(f"[RELAY] 펌프 OFF: GPIO {RELAY_PUMP_GPIO}")
        pump_relay.off()


# LED 켜기
def led_on():
    set_led(True)


# LED 끄기
def led_off():
    set_led(False)


# 펌프 작동 — gpioPin에 durationSeconds 동안 신호 출력 후 반드시 off
def pump_for_gpio(gpio_pin: int, seconds: float):
    if gpio_pin != RELAY_PUMP_GPIO:
        raise ValueError(f"등록되지 않은 펌프 GPIO입니다: {gpio_pin}")

    print(f"[RELAY] 펌프 작동: GPIO {gpio_pin}, {seconds}초")
    try:
        set_pump(True)
        sleep(seconds)
    finally:
        set_pump(False)


# 전체 릴레이 OFF — LED/펌프 모두 정지
def all_off():
    print("[RELAY] 전체 OFF")
    led_relay.off()
    pump_relay.off()


if __name__ == "__main__":
    try:
        all_off()

        input("LED 수동 확인: 엔터를 누르면 LED가 2초 켜집니다.")
        led_on()
        sleep(2)
        led_off()

        input("펌프 수동 확인: 엔터를 누르면 펌프가 1초 켜집니다.")
        pump_for_gpio(RELAY_PUMP_GPIO, 1)

    finally:
        all_off()

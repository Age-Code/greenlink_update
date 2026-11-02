# 센서 서비스 — DHT22 온습도, BH1750 조도 측정

import time
import smbus
import board
import adafruit_dht

from config import BH1750_I2C_BUS, BH1750_ADDR, DHT_GPIO


BH1750_POWER_ON = 0x01
BH1750_RESET = 0x07
BH1750_CONTINUOUS_HIGH_RES_MODE = 0x10


_bus = smbus.SMBus(BH1750_I2C_BUS)


# DHT GPIO 매핑 — BCM 번호를 board 핀으로 변환
def _get_dht_board_pin():
    if DHT_GPIO == 4:
        return board.D4
    if DHT_GPIO == 17:
        return board.D17
    if DHT_GPIO == 27:
        return board.D27
    if DHT_GPIO == 22:
        return board.D22
    if DHT_GPIO == 23:
        return board.D23

    raise ValueError(f"지원하지 않는 DHT GPIO 번호입니다: {DHT_GPIO}")


_dht = adafruit_dht.DHT22(_get_dht_board_pin(), use_pulseio=False)


# BH1750 조도 측정 — lux 값을 소수 둘째 자리로 반환
def read_bh1750_lux() -> float:
    _bus.write_byte(BH1750_ADDR, BH1750_POWER_ON)
    _bus.write_byte(BH1750_ADDR, BH1750_RESET)
    _bus.write_byte(BH1750_ADDR, BH1750_CONTINUOUS_HIGH_RES_MODE)

    time.sleep(0.2)

    data = _bus.read_i2c_block_data(
        BH1750_ADDR,
        BH1750_CONTINUOUS_HIGH_RES_MODE,
        2
    )

    lux = ((data[0] << 8) | data[1]) / 1.2

    return round(lux, 2)


# DHT22 값 검증 — 온도/습도 범위 확인
def _is_valid_temp_hum(temp, hum) -> bool:
    if temp is None or hum is None:
        return False

    if not (0 <= temp <= 50):
        return False

    if not (0 <= hum <= 100):
        return False

    return True


# DHT22 온습도 측정 — 재시도 후 온도/습도 반환
def read_dht22(max_retry: int = 5):
    for attempt in range(max_retry):
        try:
            temp = _dht.temperature
            hum = _dht.humidity

            if _is_valid_temp_hum(temp, hum):
                return round(temp, 1), round(hum, 1)

            print(f"[DHT22] 유효하지 않은 값: temp={temp}, hum={hum}")

        except RuntimeError as e:
            print(f"[DHT22] 읽기 재시도 {attempt + 1}/{max_retry}: {e}")

        time.sleep(1.0)

    return None, None


# 전체 센서 측정 — 조도/온도/습도 dict 반환
def read_all_sensors():
    lux = None
    temp = None
    hum = None

    try:
        lux = read_bh1750_lux()
    except Exception as e:
        print(f"[BH1750] 읽기 실패: {e}")

    try:
        temp, hum = read_dht22()
    except Exception as e:
        print(f"[DHT22] 읽기 실패: {e}")

    return {
        "lightLux": lux,
        "temperatureC": temp,
        "humidityPercent": hum,
    }


# 센서 리소스 정리 — DHT/I2C close
def cleanup_sensors():
    try:
        _dht.exit()
    except Exception:
        pass

    try:
        _bus.close()
    except Exception:
        pass


if __name__ == "__main__":
    try:
        sensor_data = read_all_sensors()
        print(f"[SENSOR_SERVICE] sensor_data = {sensor_data}")

    finally:
        cleanup_sensors()

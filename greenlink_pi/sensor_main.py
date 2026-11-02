# 센서 수집 진입점 — 1회 측정 후 업로드

from sensor_service import read_all_sensors, cleanup_sensors
from sensor_uploader import upload_sensor_data_safe


# 센서 측정값 출력 — 조도/온도/습도 로그
def print_sensor_data(sensor_data: dict):
    print(f"[SENSOR_MAIN] lightLux = {sensor_data.get('lightLux')}")
    print(f"[SENSOR_MAIN] temperatureC = {sensor_data.get('temperatureC')}")
    print(f"[SENSOR_MAIN] humidityPercent = {sensor_data.get('humidityPercent')}")


# 실행 진입점
def main():
    try:
        sensor_data = read_all_sensors()

        print_sensor_data(sensor_data)

        print("[SENSOR_MAIN] 센서 업로드 시작")
        upload_sensor_data_safe(sensor_data)

    finally:
        cleanup_sensors()


if __name__ == "__main__":
    main()

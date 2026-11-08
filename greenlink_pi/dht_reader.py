# DHT22 커널 드라이버(IIO) 읽기
#
# /boot/firmware/config.txt 에 `dtoverlay=dht11,gpiopin=4` 를 넣으면 리눅스 커널 dht11 드라이버가
# 센서를 직접 읽는다(DHT11·DHT22 모두 지원). 신호 타이밍을 커널이 맞추므로 파이썬에서 GPIO를
# 직접 재는 adafruit_dht 방식보다 Pi 3처럼 느린 보드에서 훨씬 안정적이다.
# 값은 /sys/bus/iio/devices/iio:deviceN/ 아래 파일로 노출된다(밀리 단위 정수).

from pathlib import Path

IIO_DEVICES_DIR = Path("/sys/bus/iio/devices")
DHT_DRIVER_NAMES = ("dht11", "dht22")


# 커널 DHT 장치 경로 찾기 — 오버레이가 없으면 None
def find_iio_dht(devices_dir: Path = IIO_DEVICES_DIR) -> Path | None:
    if not devices_dir.is_dir():
        return None

    for device in sorted(devices_dir.glob("iio:device*")):
        try:
            name = (device / "name").read_text().strip()
        except OSError:
            continue

        if name in DHT_DRIVER_NAMES:
            return device

    return None


# 한 번 읽기 — 실패하면 OSError(센서 응답 없음·체크섬 오류 등)를 그대로 올린다.
def read_iio_dht(device: Path) -> tuple[float, float]:
    temperature_milli = int((device / "in_temp_input").read_text().strip())
    humidity_milli = int((device / "in_humidityrelative_input").read_text().strip())

    return temperature_milli / 1000.0, humidity_milli / 1000.0

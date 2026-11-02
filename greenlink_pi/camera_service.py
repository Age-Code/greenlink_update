# LEGACY: Picamera2 직접 still 캡처 — 현재 active 경로 아님

from datetime import datetime
from pathlib import Path
import time

from picamera2 import Picamera2
from PIL import Image, ImageOps

from config import (
    IMAGE_DIR,
    IMAGE_ROTATE_DEGREES,
    IMAGE_FLIP_LEFT_RIGHT,
)


# 이미지 방향 보정 — 회전/좌우반전 설정 적용
def fix_image_orientation(image_path: Path):

    image = Image.open(image_path).convert("RGB")

    if IMAGE_ROTATE_DEGREES != 0:
        image = image.rotate(IMAGE_ROTATE_DEGREES, expand=True)

    if IMAGE_FLIP_LEFT_RIGHT:
        image = ImageOps.mirror(image)

    image.save(image_path, format="JPEG", quality=95)


# LEGACY still 이미지 촬영 — Picamera2 직접 캡처 후 방향 보정
def capture_image() -> Path:

    IMAGE_DIR.mkdir(parents=True, exist_ok=True)

    filename = IMAGE_DIR / f"sunflower_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"

    picam2 = Picamera2()

    try:
        camera_config = picam2.create_still_configuration()
        picam2.configure(camera_config)

        picam2.start()
        time.sleep(2)

        picam2.capture_file(str(filename))

        print(f"[CAMERA] 촬영 완료: {filename}")

        fix_image_orientation(filename)

        print(f"[CAMERA] 이미지 방향 보정 완료: {filename}")

        return filename

    finally:
        try:
            picam2.close()
        except Exception:
            pass

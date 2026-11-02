# 스냅샷 서비스 — MJPEG에서 JPEG 한 장 추출 후 식물별 crop

from pathlib import Path
from datetime import datetime
from typing import Tuple
import requests

from PIL import Image

from config import (
    IMAGE_DIR,
    SNAPSHOT_OUTPUT_WIDTH,
    SNAPSHOT_OUTPUT_HEIGHT,
)


# MJPEG 스냅샷 추출 — JPEG 프레임 1장을 파일로 저장
def capture_snapshot_from_mjpeg(
    stream_url: str,
    output_prefix: str,
    timeout_seconds: int = 15
) -> Path:

    IMAGE_DIR.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = IMAGE_DIR / f"{output_prefix}_{timestamp}.jpg"

    print(f"[SNAPSHOT] 스트림 접속: {stream_url}")

    response = requests.get(
        stream_url,
        stream=True,
        timeout=timeout_seconds
    )

    response.raise_for_status()

    buffer = b""

    try:
        for chunk in response.iter_content(chunk_size=4096):
            if not chunk:
                continue

            buffer += chunk

            start = buffer.find(b"\xff\xd8")
            end = buffer.find(b"\xff\xd9")

            if start != -1 and end != -1 and end > start:
                jpg_bytes = buffer[start:end + 2]

                output_path.write_bytes(jpg_bytes)

                print(f"[SNAPSHOT] 원본 프레임 저장 완료: {output_path}")

                return output_path

    finally:
        response.close()

    raise RuntimeError("MJPEG 스트림에서 JPEG 프레임을 추출하지 못했습니다.")


# 이미지 crop — 비율 영역을 앱 표시 크기로 저장
def crop_image_by_ratio(
    source_image_path: Path,
    crop_ratio: Tuple[float, float, float, float],
    output_prefix: str
) -> Path:

    if not source_image_path.exists():
        raise FileNotFoundError(f"원본 이미지가 없습니다: {source_image_path}")

    image = Image.open(source_image_path).convert("RGB")

    w, h = image.size

    x1_ratio, y1_ratio, x2_ratio, y2_ratio = crop_ratio

    x1 = int(w * x1_ratio)
    y1 = int(h * y1_ratio)
    x2 = int(w * x2_ratio)
    y2 = int(h * y2_ratio)

    # 안전 보정
    x1 = max(0, min(x1, w - 1))
    y1 = max(0, min(y1, h - 1))
    x2 = max(x1 + 1, min(x2, w))
    y2 = max(y1 + 1, min(y2, h))

    cropped = image.crop((x1, y1, x2, y2))

    # crop한 이미지를 앱에서 크게 보이도록 1920x1080으로 확대
    cropped = cropped.resize(
        (SNAPSHOT_OUTPUT_WIDTH, SNAPSHOT_OUTPUT_HEIGHT),
        Image.Resampling.LANCZOS
    )

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = IMAGE_DIR / f"{output_prefix}_{timestamp}.jpg"

    cropped.save(output_path, format="JPEG", quality=95)

    print(f"[SNAPSHOT] crop 저장 완료: {output_path}")

    return output_path


# 식물별 스냅샷 생성 — 전체 프레임에서 해바라기/바질 crop
def create_plant_snapshots_from_full_stream(
    full_stream_url: str,
    sunflower_crop: Tuple[float, float, float, float],
    basil_crop: Tuple[float, float, float, float]
):

    original_frame_path = capture_snapshot_from_mjpeg(
        stream_url=full_stream_url,
        output_prefix="full_snapshot"
    )

    sunflower_image_path = crop_image_by_ratio(
        source_image_path=original_frame_path,
        crop_ratio=sunflower_crop,
        output_prefix="sunflower"
    )

    basil_image_path = crop_image_by_ratio(
        source_image_path=original_frame_path,
        crop_ratio=basil_crop,
        output_prefix="basil"
    )

    return sunflower_image_path, basil_image_path, original_frame_path

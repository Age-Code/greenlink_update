# 스냅샷 서비스 — MJPEG에서 JPEG 한 장 추출

from pathlib import Path
from datetime import datetime
import requests

from config import IMAGE_DIR


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


# 식물 스냅샷 생성 — 식물 한 개 기준이므로 전체 프레임을 그대로 사용
def create_plant_snapshot_from_full_stream(full_stream_url: str) -> Path:
    return capture_snapshot_from_mjpeg(
        stream_url=full_stream_url,
        output_prefix="plant"
    )

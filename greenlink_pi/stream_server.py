# MJPEG 스트림 서버 — Flask로 전체 화면 스트림 제공 (식물 한 개 기준)

import io
import time
import threading

from flask import Flask, Response, render_template_string
from picamera2 import Picamera2
from PIL import Image, ImageDraw


# 기본 서버 설정

HOST = "0.0.0.0"
PORT = 8000


# 카메라 해상도 설정
# 카메라 원본 프레임 해상도입니다. 식물 한 개를 전체 화면으로 송출합니다.

FRAME_WIDTH = 1640
FRAME_HEIGHT = 1232


# 스트리밍 품질 설정

JPEG_QUALITY = 80

# 프레임 캡처 간격
# 0.08초 ≒ 약 12.5fps
# 라즈베리파이가 버벅이면 0.12 또는 0.15로 늘리면 됩니다.
CAPTURE_INTERVAL_SECONDS = 0.08

# MJPEG 전송 간격
# 실제 프레임 갱신은 CAPTURE_INTERVAL_SECONDS의 영향을 더 많이 받습니다.
STREAM_INTERVAL_SECONDS = 0.03


# 카메라 방향 보정
# 카메라가 뒤집혀 달려 있으므로 180도 회전 적용.
# 정상 방향이면 False로 바꾸면 됩니다.

ROTATE_180 = True


# 라벨 표시 여부
# 화면에 식물 라벨을 표시할지 여부입니다.
# 앱/공개 스트림에서 라벨이 거슬리면 False로 바꾸면 됩니다.

SHOW_LABEL = True


# 전역 객체

app = Flask(__name__)

picam2 = None
latest_frame = None
frame_lock = threading.Lock()
camera_running = False


# 로컬 확인용 HTML 페이지

INDEX_HTML = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>GreenLink Live Camera</title>
    <style>
        body {
            margin: 0;
            padding: 24px;
            background: #111;
            color: #fff;
            font-family: Arial, sans-serif;
        }

        h1 {
            margin-bottom: 8px;
        }

        p {
            color: #ccc;
        }

        .grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 24px;
        }

        .card {
            background: #222;
            padding: 16px;
            border-radius: 12px;
        }

        img {
            width: 100%;
            max-width: 1200px;
            border-radius: 12px;
            background: #000;
        }

        a {
            color: #8ee99a;
        }

        code {
            color: #8ee99a;
        }
    </style>
</head>
<body>
    <h1>GreenLink Live Camera</h1>
    <p>Raspberry Pi Camera MJPEG Stream</p>

    <div class="grid">
        <div class="card">
            <h2>Full Stream</h2>
            <p><a href="/stream.mjpg">/stream.mjpg</a></p>
            <img src="/stream.mjpg">
        </div>
    </div>
</body>
</html>
"""


# 카메라 초기화 — Picamera2 스트림 설정 후 시작
def init_camera():
    global picam2

    picam2 = Picamera2()

    camera_config = picam2.create_video_configuration(
        main={
            "size": (FRAME_WIDTH, FRAME_HEIGHT),
            "format": "RGB888",
        }
    )

    picam2.configure(camera_config)
    picam2.start()

    # 카메라 노출/초점 안정화 대기
    time.sleep(2)

    print("[STREAM] Camera started")
    print(f"[STREAM] Resolution: {FRAME_WIDTH}x{FRAME_HEIGHT}")
    print(f"[STREAM] ROTATE_180: {ROTATE_180}")


# 카메라 캡처 루프 — 최신 프레임을 전역 버퍼에 갱신
def camera_capture_loop():
    global latest_frame, camera_running

    camera_running = True

    while camera_running:
        try:
            frame = picam2.capture_array()

            # 카메라가 뒤집혀 달린 경우 180도 회전
            # numpy array 기준: 위아래 + 좌우 반전 = 180도 회전
            if ROTATE_180:
                frame = frame[::-1, ::-1].copy()

            with frame_lock:
                latest_frame = frame

            time.sleep(CAPTURE_INTERVAL_SECONDS)

        except Exception as e:
            print(f"[STREAM] Camera capture error: {e}")
            time.sleep(1)


# 최신 프레임 조회 — lock 보호 후 PIL 이미지 반환
def get_latest_image() -> Image.Image | None:
    with frame_lock:
        if latest_frame is None:
            return None

        frame_copy = latest_frame.copy()

    return Image.fromarray(frame_copy).convert("RGB")


# 스트림 라벨 표시 — 설정이 켜진 경우 식물명 overlay
def draw_label(image: Image.Image, label: str) -> Image.Image:
    if not SHOW_LABEL:
        return image

    result = image.copy()
    draw = ImageDraw.Draw(result)

    # 라벨 박스
    box_left = 16
    box_top = 16
    box_right = 300
    box_bottom = 74

    draw.rectangle(
        (box_left, box_top, box_right, box_bottom),
        fill=(0, 0, 0)
    )

    draw.text(
        (box_left + 16, box_top + 20),
        label,
        fill=(255, 255, 255)
    )

    return result


# JPEG 인코딩 — PIL 이미지를 MJPEG frame bytes로 변환
def image_to_jpeg_bytes(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=JPEG_QUALITY)
    return buffer.getvalue()


# MJPEG 생성 — stream_type별 frame yield
def generate_mjpeg(stream_type: str):
    while True:
        image = get_latest_image()

        if image is None:
            time.sleep(0.1)
            continue

        try:
            if stream_type == "full":
                # 전체 화면을 crop 없이 원본 해상도 그대로 송출
                image = draw_label(image, "Full")

            else:
                image = draw_label(image, "Unknown")

            jpeg_bytes = image_to_jpeg_bytes(image)

            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" +
                jpeg_bytes +
                b"\r\n"
            )

            time.sleep(STREAM_INTERVAL_SECONDS)

        except GeneratorExit:
            print(f"[STREAM] Client disconnected: {stream_type}")
            break

        except Exception as e:
            print(f"[STREAM] MJPEG generation error ({stream_type}): {e}")
            time.sleep(0.5)


# 스트림 확인 페이지 렌더링
@app.route("/")
def index():
    return render_template_string(INDEX_HTML)


# 스트림 서버 상태 응답
@app.route("/health")
def health():
    return {
        "status": "ok",
        "service": "greenlink-stream",
        "resolution": {
            "width": FRAME_WIDTH,
            "height": FRAME_HEIGHT,
        },
        "rotate180": ROTATE_180,
        "showLabel": SHOW_LABEL,
        "streams": {
            "full": "/stream.mjpg",
        },
    }


# 전체 MJPEG 스트림 응답
@app.route("/stream.mjpg")
def stream_full():
    return Response(
        generate_mjpeg("full"),
        mimetype="multipart/x-mixed-replace; boundary=frame"
    )


# 실행 진입점
def main():
    init_camera()

    capture_thread = threading.Thread(
        target=camera_capture_loop,
        daemon=True
    )
    capture_thread.start()

    print(f"[STREAM] Server starting on {HOST}:{PORT}")
    print("[STREAM] Available streams:")
    print("[STREAM] - /stream.mjpg")

    app.run(
        host=HOST,
        port=PORT,
        threaded=True
    )


if __name__ == "__main__":
    try:
        main()

    finally:
        camera_running = False

        if picam2 is not None:
            try:
                picam2.stop()
                picam2.close()
            except Exception:
                pass

        print("[STREAM] Camera stopped")

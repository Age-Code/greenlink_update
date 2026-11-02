# 배경/화분 제거 — rembg 전처리 후 하단 화분 영역 투명화

from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io
import numpy as np


MODEL_NAME = "u2netp"

ALPHA_THRESHOLD = 12
BOTTOM_PAD_PX = 28

FALLBACK_TRIM_RATIO = 0.24


# 하단 투명 padding 추가 — crop 후 식물 하단 여백 확보
def add_bottom_padding(rgba: Image.Image, bottom_pad_px: int):
    if bottom_pad_px <= 0:
        return rgba

    w, h = rgba.size
    rgba_canvas = Image.new("RGBA", (w, h + bottom_pad_px), (0, 0, 0, 0))
    rgba_canvas.paste(rgba, (0, 0))
    return rgba_canvas


# 하단 화분 영역 투명화 — rembg 결과의 하단 비율 제거
def simple_remove_lower_pot(rgba: Image.Image) -> Image.Image:

    alpha = np.array(rgba.getchannel("A"), dtype=np.uint8)
    mask = alpha > ALPHA_THRESHOLD

    rows = np.where(mask.any(axis=1))[0]

    if len(rows) == 0:
        return rgba

    y_top = int(rows[0])
    y_bottom = int(rows[-1])
    obj_h = max(1, y_bottom - y_top + 1)

    cut_y = y_bottom - int(obj_h * FALLBACK_TRIM_RATIO)

    rgba_np = np.array(rgba, dtype=np.uint8)
    rgba_np[cut_y:, :, 3] = 0

    transparent_mask = rgba_np[..., 3] == 0
    rgba_np[..., 0][transparent_mask] = 0
    rgba_np[..., 1][transparent_mask] = 0
    rgba_np[..., 2][transparent_mask] = 0

    return Image.fromarray(rgba_np, mode="RGBA")


# 배경/화분 제거 — rembg 후 투명 PNG와 debug 이미지 저장
def remove_background_and_pot(
    input_path: Path,
    output_transparent_path: Path,
    output_debug_path: Path | None = None,
    session=None,
):
    if session is None:
        session = new_session(MODEL_NAME)

    input_bytes = input_path.read_bytes()

    output_bytes = remove(
        input_bytes,
        session=session,
        force_return_bytes=True,
    )

    rgba = Image.open(io.BytesIO(output_bytes)).convert("RGBA")

    rgba = simple_remove_lower_pot(rgba)
    rgba = add_bottom_padding(rgba, BOTTOM_PAD_PX)

    output_transparent_path.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(output_transparent_path, format="PNG")

    if output_debug_path is not None:
        output_debug_path.parent.mkdir(parents=True, exist_ok=True)
        debug_black = Image.new("RGBA", rgba.size, (0, 0, 0, 255))
        debug_comp = Image.alpha_composite(debug_black, rgba).convert("RGB")
        debug_comp.save(output_debug_path, format="PNG")

    return output_transparent_path

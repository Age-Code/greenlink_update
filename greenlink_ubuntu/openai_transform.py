# OpenAI 스타일 변환 — gpt-image-1.5 edit으로 GreenLink 스타일 이미지 생성

from pathlib import Path
import base64
import os

from dotenv import load_dotenv
from openai import OpenAI


load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


PROMPT = """Image 1 is the source plant image.
Image 2 is only a visual style reference for the GreenLink app.

Your task is to redraw the exact same plant from Image 1.
Do not design a new plant.
Do not create a generic sprout.
Do not make a prettier, cleaner, more balanced, or more symmetrical plant.
Do not copy the plant shape from Image 2.
Image 2 must be used only for color mood, softness, texture, and illustration finish.

The plant structure from Image 1 is the highest priority.

Strict structure preservation rules:
- Preserve the same overall silhouette from Image 1.
- Preserve the same leaf count as much as possible.
- Preserve the position, direction, angle, and relative size of the leaves.
- Preserve the stem direction, length, curvature, and visible branching.
- Preserve the asymmetry of the original plant.
- Preserve the original growth stage.
- Do not add new leaves.
- Do not remove important visible leaves.
- Do not rearrange leaves.
- Do not turn the plant into a symmetrical icon.
- Do not replace the plant with a four-leaf sprout.
- Do not simplify the plant into a logo-like symbol.
- Do not change the species or make it look like a different plant.

Rendering style:
- Convert the source plant into a soft GreenLink-style illustration.
- Use gentle green colors, smooth edges, and soft shading.
- Make it look friendly and suitable for a mobile app.
- Simplify only the surface texture, not the shape.
- The result should still be recognizable as the same plant from Image 1.

Background and object rules:
- Keep only the plant.
- Do not generate any pot, planter, soil, container, sensor, wire, label, decorative object, or background scene.
- If there are small non-plant artifacts in Image 1, ignore them.
- Keep the plant isolated and ready to be composited onto a separate pot asset.

Final requirement:
The final image must look like Image 1 redrawn in the soft visual style of Image 2.
The shape must come from Image 1.
The style must come from Image 2.
"""



# OpenAI 스타일 변환 — source/style 이미지로 gpt-image edit 실행
def transform_to_greenlink_style(
    source_transparent_path: Path,
    style_image_path: Path,
    output_path: Path,
):
    if not source_transparent_path.exists():
        raise FileNotFoundError(f"소스 이미지가 없습니다: {source_transparent_path}")

    if not style_image_path.exists():
        raise FileNotFoundError(f"스타일 이미지가 없습니다: {style_image_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(source_transparent_path, "rb") as img1, open(style_image_path, "rb") as img2:
        result = client.images.edit(
            model="gpt-image-1.5",
            image=[img1, img2],
            prompt=PROMPT,
            input_fidelity="high",
        )

    image_base64 = result.data[0].b64_json

    output_path.write_bytes(base64.b64decode(image_base64))

    return output_path

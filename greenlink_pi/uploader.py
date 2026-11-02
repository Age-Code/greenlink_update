# 이미지 업로드 — 백엔드 multipart POST 후 AI trigger

from pathlib import Path
from datetime import datetime
import requests

from config import DEVICE_KEY, SERVER_IMAGE_URL
from ai_trigger import trigger_ai_worker


# 이미지 업로드 — Backend multipart POST 후 AI Worker 호출
def upload_image(
    image_path: Path,
    user_plant_id: int,
):

    image_path = Path(image_path)

    if not image_path.exists():
        raise FileNotFoundError(f"이미지 파일이 없습니다: {image_path}")

    headers = {
        "X-DEVICE-KEY": DEVICE_KEY,
    }

    data = {
        "userPlantId": str(user_plant_id),
        "capturedAt": datetime.now().isoformat(timespec="seconds"),
    }

    print("[IMAGE_UPLOAD] 업로드 시작")
    print(f"[IMAGE_UPLOAD] image_path: {image_path}")
    print(f"[IMAGE_UPLOAD] userPlantId: {user_plant_id}")
    print(f"[IMAGE_UPLOAD] URL: {SERVER_IMAGE_URL}")

    with image_path.open("rb") as file:
        files = {
            "file": (
                image_path.name,
                file,
                "image/jpeg",
            )
        }

        response = requests.post(
            SERVER_IMAGE_URL,
            headers=headers,
            data=data,
            files=files,
            timeout=60,
        )

    print(f"[IMAGE_UPLOAD] 응답 코드: {response.status_code}")
    print(f"[IMAGE_UPLOAD] 응답 본문: {response.text}")

    response.raise_for_status()

    result = response.json()

    if not result.get("success"):
        raise RuntimeError(f"이미지 업로드 실패: {result}")

    upload_data = result.get("data")

    if upload_data is None:
        raise RuntimeError(f"이미지 업로드 응답에 data가 없습니다: {result}")

    plant_image_id = upload_data.get("plantImageId")
    uploaded_user_plant_id = upload_data.get("userPlantId")
    image_url = upload_data.get("imageUrl")

    if plant_image_id is None:
        raise RuntimeError(f"plantImageId가 없습니다: {upload_data}")

    if uploaded_user_plant_id is None:
        uploaded_user_plant_id = user_plant_id

    if image_url is None or image_url == "":
        raise RuntimeError(f"imageUrl이 없습니다: {upload_data}")

    print("[IMAGE_UPLOAD] 업로드 성공")
    print(f"[IMAGE_UPLOAD] plantImageId: {plant_image_id}")
    print(f"[IMAGE_UPLOAD] userPlantId: {uploaded_user_plant_id}")
    print(f"[IMAGE_UPLOAD] imageUrl: {image_url}")

    try:
        ai_result = trigger_ai_worker(
            plant_image_id=plant_image_id,
            user_plant_id=uploaded_user_plant_id,
            image_url=image_url,
        )

        print("[AI_TRIGGER] AI Worker 호출 성공")
        print(f"[AI_TRIGGER] 결과: {ai_result}")

        result["aiTriggerSuccess"] = True
        result["aiTriggerResult"] = ai_result

    except Exception as e:
        print("[AI_TRIGGER] AI Worker 호출 실패")
        print(f"[AI_TRIGGER] 오류: {e}")

        # 사진 업로드 자체는 성공했으므로 여기서 전체 실패로 만들지는 않는다.
        result["aiTriggerSuccess"] = False
        result["aiTriggerError"] = str(e)

    return result


# 이미지 업로드 후 삭제 — Backend 업로드 성공 시 로컬 파일 제거
def upload_image_and_delete_if_success(
    image_path: Path,
    user_plant_id: int,
):

    image_path = Path(image_path)

    result = upload_image(
        image_path=image_path,
        user_plant_id=user_plant_id,
    )

    if result.get("success") and image_path.exists():
        image_path.unlink()
        print(f"[IMAGE_UPLOAD] 로컬 이미지 삭제 완료: {image_path}")

    return result

# AI 트리거 — Ubuntu AI Worker /process POST

import requests

from config import AI_PROCESS_SECRET, AI_WORKER_URL


# AI Worker 호출 — 업로드 이미지 URL로 /process 요청
def trigger_ai_worker(
    plant_image_id: int,
    user_plant_id: int,
    image_url: str,
):

    name = f"user_plant_{user_plant_id}_image_{plant_image_id}"

    payload = {
        "plantImageId": plant_image_id,
        "userPlantId": user_plant_id,
        "imageUrl": image_url,
        "name": name,
    }

    print("[AI_TRIGGER] AI Worker 요청 시작")
    print(f"[AI_TRIGGER] URL: {AI_WORKER_URL}")
    print(f"[AI_TRIGGER] payload: {payload}")

    response = requests.post(
        AI_WORKER_URL,
        json=payload,
        headers={"X-AI-Process-Secret": AI_PROCESS_SECRET},
        timeout=10,
    )

    print(f"[AI_TRIGGER] 응답 코드: {response.status_code}")
    print(f"[AI_TRIGGER] 응답 본문: {response.text}")

    response.raise_for_status()

    return response.json()

# AI Worker FastAPI 서버 — /health, /process 엔드포인트

from datetime import datetime
import hmac
import os

from fastapi import FastAPI, BackgroundTasks, Header, HTTPException
from pydantic import BaseModel

from job_name import validate_job_name
from process_one import process_one


app = FastAPI(title="GreenLink AI Worker")

# Pi가 /process 호출 시 보내는 공유 secret — 미설정이면 모든 요청 거부
AI_PROCESS_SECRET = os.environ.get("AI_PROCESS_SECRET", "")


# /process 인증 — X-AI-Process-Secret 헤더 상수 시간 비교
def verify_process_secret(header_value: str | None) -> None:
    if not AI_PROCESS_SECRET:
        raise HTTPException(status_code=503, detail="AI_PROCESS_SECRET is not configured")

    if header_value is None or not hmac.compare_digest(
        header_value.encode("utf-8"),
        AI_PROCESS_SECRET.encode("utf-8"),
    ):
        raise HTTPException(status_code=401, detail="Invalid AI process secret")


# AI 처리 요청 모델 — plantImageId, imageUrl, 선택 이름 포함
class ProcessRequest(BaseModel):
    plantImageId: int
    userPlantId: int | None = None
    imageUrl: str
    name: str | None = None


# AI Worker 상태 확인 응답
@app.get("/health")
def health_check():
    return {
        "success": True,
        "message": "GreenLink AI Worker is running",
    }


# AI 작업명 생성 — 요청 이름 우선, 없으면 timestamp 사용
def make_job_name(request: ProcessRequest) -> str:
    name = request.name

    if name is not None:
        return validate_job_name(name)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    if request.userPlantId is not None:
        generated_name = f"user_plant_{request.userPlantId}_image_{request.plantImageId}_{timestamp}"
        return validate_job_name(generated_name)

    return validate_job_name(f"plant_image_{request.plantImageId}_{timestamp}")


# AI background 작업 실행 — process_one 호출 후 결과 로깅
def run_ai_job(
    image_url: str,
    name: str,
    plant_image_id: int,
):
    try:
        print("===== GreenLink AI Background Job Start =====")
        print(f"[AI_WORKER] plantImageId: {plant_image_id}")
        print(f"[AI_WORKER] imageUrl: {image_url}")
        print(f"[AI_WORKER] name: {name}")

        result = process_one(
            image_url=image_url,
            name=name,
            plant_image_id=plant_image_id,
        )

        print("===== GreenLink AI Background Job Done =====")
        print(f"[AI_WORKER] result: {result}")

    except Exception as e:
        print("===== GreenLink AI Background Job Failed =====")
        print(f"[AI_WORKER] error: {e}")


# AI 처리 요청 접수 — background task 등록
@app.post("/process")
def process_image(
    request: ProcessRequest,
    background_tasks: BackgroundTasks,
    x_ai_process_secret: str | None = Header(default=None),
):
    verify_process_secret(x_ai_process_secret)

    try:
        name = make_job_name(request)
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error

    background_tasks.add_task(
        run_ai_job,
        request.imageUrl,
        name,
        request.plantImageId,
    )

    return {
        "success": True,
        "message": "AI processing started",
        "data": {
            "plantImageId": request.plantImageId,
            "userPlantId": request.userPlantId,
            "imageUrl": request.imageUrl,
            "name": name,
            "status": "PROCESSING",
        },
    }

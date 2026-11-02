# AI 이미지 처리 파이프라인 — 다운로드→전처리→변환→S3→callback

from pathlib import Path
from urllib.parse import urlparse
import argparse
import os
import requests

from rembg import new_session

from job_name import validate_job_name
from remove_pot import MODEL_NAME, remove_background_and_pot
from openai_transform import transform_to_greenlink_style
from s3_client import download_source_image_from_s3, upload_file_to_s3


BASE_DIR = Path(__file__).resolve().parent
INPUT_DIR = BASE_DIR / "inputs"
OUTPUT_DIR = BASE_DIR / "outputs"

STYLE_IMAGE_PATH = BASE_DIR / "style_plant.png"

BACKEND_BASE_URL = os.environ.get("BACKEND_BASE_URL", "")
AI_WORKER_SECRET = os.environ.get("AI_WORKER_SECRET", "")


# 원본 이미지 다운로드 — 검증된 S3 object를 로컬 파일로 저장
def download_image(url: str, output_path: Path) -> Path:
    return download_source_image_from_s3(url, output_path)


# 원본 S3 파일명 추출 — 확장자 없는 stem 반환
def extract_original_stem_from_url(image_url: str) -> str:

    parsed = urlparse(image_url)
    filename = Path(parsed.path).name

    if filename is None or filename.strip() == "":
        raise ValueError("imageUrl에서 파일명을 추출할 수 없습니다.")

    return Path(filename).stem


# 최종 AI S3 key 생성 — 원본 stem 기반 PNG 경로
def build_final_ai_s3_key_from_image_url(image_url: str) -> str:

    original_stem = extract_original_stem_from_url(image_url)

    return f"greenlink/ai/userplant/{original_stem}.png"


# 최종 AI 결과 업로드 — S3 URL과 key 반환
def upload_final_result_to_s3(
    image_url: str,
    ai_result_path: Path,
) -> dict:
    print("[AI] 최종 AI 결과 S3 업로드 시작")

    final_ai_s3_key = build_final_ai_s3_key_from_image_url(image_url)

    print(f"[AI] final_ai_s3_key: {final_ai_s3_key}")

    final_ai_url = upload_file_to_s3(
        ai_result_path,
        final_ai_s3_key,
    )

    print(f"[AI] final_ai_url: {final_ai_url}")

    return {
        "finalAiUrl": final_ai_url,
        "finalAiS3Key": final_ai_s3_key,
    }


# AI 결과 callback — X-AI-Worker-Secret 헤더로 Backend 저장
def save_ai_result_to_backend(
    plant_image_id: int,
    final_ai_url: str,
    backend_base_url: str = BACKEND_BASE_URL,
) -> dict:
    if not backend_base_url:
        raise RuntimeError("BACKEND_BASE_URL 환경변수가 없습니다. .env를 확인하세요.")

    if not AI_WORKER_SECRET:
        raise RuntimeError("AI_WORKER_SECRET 환경변수가 없습니다. .env를 확인하세요.")

    api_url = f"{backend_base_url}/api/ai/plant-images/{plant_image_id}/result"

    payload = {
        "finalAiUrl": final_ai_url,
    }

    print("[AI] 백엔드에 AI 결과 저장 요청")
    print(f"[AI] 요청 URL: {api_url}")
    print(f"[AI] payload: {payload}")

    response = requests.post(
        api_url,
        json=payload,
        headers={"X-AI-Worker-Secret": AI_WORKER_SECRET},
        timeout=30,
    )

    print(f"[AI] 백엔드 응답 코드: {response.status_code}")
    print(f"[AI] 백엔드 응답 내용: {response.text}")

    response.raise_for_status()

    return response.json()


# 로컬 파일 cleanup — 처리 산출물 삭제 실패는 경고만 출력
def cleanup_local_files(paths: list):
    for path in paths:
        try:
            if path is not None and Path(path).exists():
                Path(path).unlink()
                print(f"[AI] 로컬 파일 삭제 완료: {path}")
        except Exception as e:
            print(f"[AI] 로컬 파일 삭제 실패 (무시): {path} — {e}")


# AI 이미지 처리 파이프라인 — 다운로드→전처리→변환→S3→callback
def process_one(
    image_url: str,
    name: str,
    plant_image_id: int | None = None,
    backend_base_url: str = BACKEND_BASE_URL,
) -> dict:

    name = validate_job_name(name)

    INPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if not STYLE_IMAGE_PATH.exists():
        raise FileNotFoundError(f"스타일 이미지가 없습니다: {STYLE_IMAGE_PATH}")

    print("[AI] [1/6] 원본 이미지 다운로드")

    original_path = INPUT_DIR / f"{name}_original.jpg"

    download_image(
        url=image_url,
        output_path=original_path,
    )

    print(f"[AI] 원본 이미지 저장: {original_path}")

    print("[AI] [2/6] 원본 배경/화분 제거용 rembg 세션 로딩")

    session = new_session(MODEL_NAME)

    print("[AI] [3/6] 원본 배경/화분 제거")

    source_transparent_path = OUTPUT_DIR / f"{name}_source_transparent.png"
    source_debug_path = OUTPUT_DIR / f"{name}_source_debug_black.png"

    # remove_pot.py의 기존 함수 정의에 맞춰 순서 인자로 호출
    remove_background_and_pot(
        original_path,
        source_transparent_path,
        source_debug_path,
        session,
    )

    print(f"[AI] 원본 투명 이미지 저장: {source_transparent_path}")
    print(f"[AI] 원본 디버그 이미지 저장: {source_debug_path}")

    print("[AI] [4/6] OpenAI 스타일 변환 - 식물만 변환")

    # 중요:
    # AI 변환 결과가 잘 나오던 기존 파일명 구조를 유지한다.
    # S3 업로드할 때만 원본 imageUrl 기준 파일명으로 저장한다.
    ai_result_path = OUTPUT_DIR / f"{name}_greenlink_ai.png"

    # openai_transform.py의 기존 함수 정의에 맞춰 순서 인자로 호출
    transform_to_greenlink_style(
        source_transparent_path,
        STYLE_IMAGE_PATH,
        ai_result_path,
    )

    print(f"[AI] AI 최종 이미지 저장: {ai_result_path}")

    print("[AI] [5/6] 최종 AI 결과 S3 업로드")

    urls = upload_final_result_to_s3(
        image_url=image_url,
        ai_result_path=ai_result_path,
    )

    backend_response = None

    if plant_image_id is not None:
        print("[AI] [6/6] 백엔드 DB 저장")

        backend_response = save_ai_result_to_backend(
            plant_image_id=plant_image_id,
            final_ai_url=urls["finalAiUrl"],
            backend_base_url=backend_base_url,
        )
    else:
        print("[AI] [6/6] plantImageId가 없어 백엔드 저장은 건너뜀")

    # S3 업로드 및 선택적 백엔드 callback 성공 후 로컬 중간 파일 삭제
    cleanup_local_files([
        original_path,
        source_transparent_path,
        source_debug_path,
        ai_result_path,
    ])

    print("[AI] 처리 완료")
    print(f"[AI] finalAiUrl: {urls['finalAiUrl']}")
    print(f"[AI] finalAiS3Key: {urls['finalAiS3Key']}")
    print(f"[AI] backendSaved: {backend_response is not None}")

    return {
        "finalAiUrl": urls["finalAiUrl"],
        "finalAiS3Key": urls["finalAiS3Key"],
        "backendSaved": backend_response is not None,
        "backendResponse": backend_response,
        "localPaths": {
            "original": str(original_path),
            "sourceTransparent": str(source_transparent_path),
            "sourceDebug": str(source_debug_path),
            "aiImage": str(ai_result_path),
        },
    }


# 실행 진입점
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--url",
        required=True,
        help="원본 S3 이미지 URL",
    )

    parser.add_argument(
        "--name",
        default="test",
        help="파일명 prefix",
    )

    parser.add_argument(
        "--plant-image-id",
        type=int,
        default=None,
        help="백엔드 plantImageId. 입력하면 AI 결과를 DB에 저장한다.",
    )

    parser.add_argument(
        "--backend-url",
        default=BACKEND_BASE_URL,
        help="Spring Boot 백엔드 주소",
    )

    args = parser.parse_args()

    process_one(
        image_url=args.url,
        name=args.name,
        plant_image_id=args.plant_image_id,
        backend_base_url=args.backend_url,
    )


if __name__ == "__main__":
    main()

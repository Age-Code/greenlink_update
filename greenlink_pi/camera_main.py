# 카메라 진입점 — 스트림 프레임 추출 후 업로드

import os

from stream_snapshot_service import create_plant_snapshot_from_full_stream
from uploader import upload_image_and_delete_if_success
from config import (
    FULL_STREAM_URL,
    USER_PLANT_ID,
)


# 업로드 결과 정규화 — tuple/dict/bool 반환 형태 통일
def normalize_upload_result(result):

    if isinstance(result, tuple):
        success = result[0] if len(result) >= 1 else False
        body = result[1] if len(result) >= 2 else None
        extra = result[2:] if len(result) >= 3 else None
        return bool(success), body, extra

    if isinstance(result, dict):
        success = result.get("success") is True
        return success, result, None

    if isinstance(result, bool):
        return result, None, None

    return False, result, None


# 식물 스냅샷 업로드 — 업로드 결과 로깅
def upload_snapshot(
    image_path,
    user_plant_id: int
):
    print("[CAMERA_MAIN] 이미지 업로드 시작")
    print(f"[CAMERA_MAIN] imagePath = {image_path}")
    print(f"[CAMERA_MAIN] userPlantId = {user_plant_id}")

    result = upload_image_and_delete_if_success(
        image_path=image_path,
        user_plant_id=user_plant_id
    )

    success, body, extra = normalize_upload_result(result)

    if success:
        print("[CAMERA_MAIN] 이미지 업로드 성공")
    else:
        print("[CAMERA_MAIN] 이미지 업로드 실패")

    if body is not None:
        print(f"[CAMERA_MAIN] 업로드 응답: {body}")

    if extra is not None:
        print(f"[CAMERA_MAIN] 추가 반환값: {extra}")

    return success, body, extra


# 스냅샷 파일 삭제 — 실패해도 경고 로그만 출력
def delete_file_if_exists(path):
    try:
        if path is not None and os.path.exists(path):
            os.remove(path)
            print(f"[CAMERA_MAIN] 임시 파일 삭제 완료: {path}")
    except Exception as e:
        print(f"[CAMERA_MAIN] 임시 파일 삭제 실패: {path} | {e}")


# 실행 진입점
def main():
    print("[CAMERA_MAIN] 일일 썸네일 스냅샷 업로드 시작")
    print(f"[CAMERA_MAIN] fullStreamUrl = {FULL_STREAM_URL}")
    print(f"[CAMERA_MAIN] userPlantId = {USER_PLANT_ID}")

    image_path = None
    success = False

    try:
        image_path = create_plant_snapshot_from_full_stream(FULL_STREAM_URL)

        print(f"[CAMERA_MAIN] snapshot = {image_path}")

        success, _, _ = upload_snapshot(
            image_path=image_path,
            user_plant_id=USER_PLANT_ID
        )

    except Exception as e:
        print(f"[CAMERA_MAIN] 스냅샷 업로드 중 오류: {e}")

    finally:
        # 업로드 성공 시 uploader가 이미 삭제한다. 실패한 파일도 쌓이지 않도록 정리한다.
        delete_file_if_exists(image_path)

    status = "성공" if success else "실패"
    print(f"[CAMERA_MAIN] 일일 썸네일 스냅샷 업로드 결과: {status}")


if __name__ == "__main__":
    main()

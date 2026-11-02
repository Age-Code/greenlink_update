# 카메라 진입점 — 스트림 프레임 추출, crop, 업로드

import os

from stream_snapshot_service import create_plant_snapshots_from_full_stream
from uploader import upload_image_and_delete_if_success
from config import (
    FULL_STREAM_URL,
    SUNFLOWER_CROP,
    BASIL_CROP,
    SUNFLOWER_USER_PLANT_ID,
    BASIL_USER_PLANT_ID,
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


# 식물 스냅샷 업로드 — 업로드 결과와 AI trigger 결과 로깅
def upload_snapshot(
    plant_name: str,
    image_path,
    user_plant_id: int
):
    print(f"[CAMERA_MAIN] {plant_name} 이미지 업로드 시작")
    print(f"[CAMERA_MAIN] imagePath = {image_path}")
    print(f"[CAMERA_MAIN] userPlantId = {user_plant_id}")

    result = upload_image_and_delete_if_success(
        image_path=image_path,
        user_plant_id=user_plant_id
    )

    success, body, extra = normalize_upload_result(result)

    if success:
        print(f"[CAMERA_MAIN] {plant_name} 이미지 업로드 성공")
    else:
        print(f"[CAMERA_MAIN] {plant_name} 이미지 업로드 실패")

    if body is not None:
        print(f"[CAMERA_MAIN] {plant_name} 업로드 응답: {body}")

    if extra is not None:
        print(f"[CAMERA_MAIN] {plant_name} 추가 반환값: {extra}")

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
    print("[CAMERA_MAIN] 아침 스냅샷 업로드 시작")
    print(f"[CAMERA_MAIN] fullStreamUrl = {FULL_STREAM_URL}")
    print(f"[CAMERA_MAIN] SUNFLOWER_CROP = {SUNFLOWER_CROP}")
    print(f"[CAMERA_MAIN] BASIL_CROP = {BASIL_CROP}")

    original_frame_path = None
    sunflower_image_path = None
    basil_image_path = None

    results = []

    try:
        sunflower_image_path, basil_image_path, original_frame_path = (
            create_plant_snapshots_from_full_stream(
                full_stream_url=FULL_STREAM_URL,
                sunflower_crop=SUNFLOWER_CROP,
                basil_crop=BASIL_CROP
            )
        )

        print("[CAMERA_MAIN] 전체 프레임 1장 기준 crop 완료")
        print(f"[CAMERA_MAIN] original = {original_frame_path}")
        print(f"[CAMERA_MAIN] sunflower = {sunflower_image_path}")
        print(f"[CAMERA_MAIN] basil = {basil_image_path}")

        try:
            sunflower_result = upload_snapshot(
                plant_name="해바라기",
                image_path=sunflower_image_path,
                user_plant_id=SUNFLOWER_USER_PLANT_ID
            )
            results.append(("해바라기", sunflower_result[0]))

        except Exception as e:
            print(f"[CAMERA_MAIN] 해바라기 업로드 중 오류: {e}")
            results.append(("해바라기", False))

        try:
            basil_result = upload_snapshot(
                plant_name="바질",
                image_path=basil_image_path,
                user_plant_id=BASIL_USER_PLANT_ID
            )
            results.append(("바질", basil_result[0]))

        except Exception as e:
            print(f"[CAMERA_MAIN] 바질 업로드 중 오류: {e}")
            results.append(("바질", False))

    finally:
        delete_file_if_exists(original_frame_path)

    print("[CAMERA_MAIN] 아침 스냅샷 업로드 결과")
    for plant_name, success in results:
        status = "성공" if success else "실패"
        print(f"[CAMERA_MAIN] {plant_name}: {status}")


if __name__ == "__main__":
    main()

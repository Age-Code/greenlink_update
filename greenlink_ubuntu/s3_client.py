# S3 원본 다운로드 및 결과 업로드

from pathlib import Path
from urllib.parse import unquote, urlsplit
import os
import mimetypes
import re
import tempfile

import boto3
from dotenv import load_dotenv


load_dotenv()


AWS_REGION = os.getenv("AWS_REGION", "ap-northeast-2")
S3_BUCKET = os.getenv("S3_BUCKET")

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
)

SOURCE_IMAGE_PREFIX = "greenlink/userplant/"
MAX_SOURCE_IMAGE_BYTES = 20 * 1024 * 1024
DOWNLOAD_CHUNK_BYTES = 64 * 1024

_SAFE_SOURCE_FILENAME_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")
_CONTENT_TYPE_BY_EXTENSION = {
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
    "webp": "image/webp",
}


# Backend가 생성한 virtual-host S3 URL에서 허용된 원본 key만 추출
def parse_source_image_s3_url(image_url: str) -> str:
    if not isinstance(image_url, str) or not image_url:
        raise ValueError("imageUrl은 비어 있지 않은 문자열이어야 합니다.")

    if "?" in image_url or "#" in image_url:
        raise ValueError("imageUrl에는 query 또는 fragment를 사용할 수 없습니다.")

    if not S3_BUCKET:
        raise RuntimeError("S3_BUCKET 환경변수가 없습니다. .env를 확인하세요.")

    try:
        parsed = urlsplit(image_url)
        port = parsed.port
    except ValueError as error:
        raise ValueError("imageUrl 형식이 올바르지 않습니다.") from error

    expected_host = f"{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com"
    allowed_netlocs = {
        expected_host,
        f"{expected_host}:443",
    }

    if parsed.scheme != "https":
        raise ValueError("imageUrl은 HTTPS S3 URL이어야 합니다.")

    if parsed.username is not None or parsed.password is not None:
        raise ValueError("imageUrl에는 사용자 정보를 포함할 수 없습니다.")

    if (
        parsed.hostname != expected_host
        or parsed.netloc.lower() not in allowed_netlocs
    ):
        raise ValueError("허용되지 않은 S3 host입니다.")

    if port not in (None, 443):
        raise ValueError("imageUrl은 기본 HTTPS 포트만 사용할 수 있습니다.")

    if parsed.query or parsed.fragment:
        raise ValueError("imageUrl에는 query 또는 fragment를 사용할 수 없습니다.")

    try:
        decoded_path = unquote(parsed.path, encoding="utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise ValueError("imageUrl 경로 인코딩이 올바르지 않습니다.") from error

    expected_path_prefix = f"/{SOURCE_IMAGE_PREFIX}"

    if not decoded_path.startswith(expected_path_prefix):
        raise ValueError("허용되지 않은 S3 key prefix입니다.")

    filename = decoded_path[len(expected_path_prefix):]

    if (
        not filename
        or filename in (".", "..")
        or "/" in filename
        or "\\" in filename
        or _SAFE_SOURCE_FILENAME_PATTERN.fullmatch(filename) is None
    ):
        raise ValueError("원본 S3 key는 prefix 아래의 단일 파일이어야 합니다.")

    extension = Path(filename).suffix.lower().lstrip(".")

    if extension not in _CONTENT_TYPE_BY_EXTENSION:
        raise ValueError("jpg, jpeg, png, webp 원본 이미지만 허용합니다.")

    return SOURCE_IMAGE_PREFIX + filename


# S3 원본 이미지를 크기 제한을 적용해 로컬 파일로 저장
def download_source_image_from_s3(
    image_url: str,
    output_path: Path,
) -> Path:
    s3_key = parse_source_image_s3_url(image_url)
    response = s3.get_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
    )

    body = response.get("Body")

    if body is None or not callable(getattr(body, "read", None)):
        raise ValueError("S3 원본 응답 body가 없습니다.")

    temporary_path = None

    try:
        content_length = response.get("ContentLength")

        if (
            not isinstance(content_length, int)
            or isinstance(content_length, bool)
            or content_length <= 0
        ):
            raise ValueError("S3 원본 ContentLength가 올바르지 않습니다.")

        if content_length > MAX_SOURCE_IMAGE_BYTES:
            raise ValueError("S3 원본 이미지는 20MiB 이하여야 합니다.")

        content_type = response.get("ContentType")

        if not isinstance(content_type, str) or not content_type.strip():
            raise ValueError("S3 원본 ContentType이 없습니다.")

        normalized_content_type = content_type.split(";", 1)[0].strip().lower()
        extension = Path(s3_key).suffix.lower().lstrip(".")
        expected_content_type = _CONTENT_TYPE_BY_EXTENSION[extension]

        if normalized_content_type != expected_content_type:
            raise ValueError("S3 원본 확장자와 ContentType이 일치하지 않습니다.")

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=output_path.parent,
            prefix=f".{output_path.name}.",
            suffix=".part",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
            downloaded_bytes = 0

            while True:
                chunk = body.read(DOWNLOAD_CHUNK_BYTES)

                if not chunk:
                    break

                if not isinstance(chunk, (bytes, bytearray)):
                    raise ValueError("S3 원본 stream 형식이 올바르지 않습니다.")

                downloaded_bytes += len(chunk)

                if downloaded_bytes > MAX_SOURCE_IMAGE_BYTES:
                    raise ValueError("S3 원본 stream이 20MiB를 초과했습니다.")

                temporary_file.write(chunk)

        if downloaded_bytes == 0:
            raise ValueError("S3 원본 이미지가 비어 있습니다.")

        if downloaded_bytes != content_length:
            raise ValueError("S3 원본 ContentLength와 실제 크기가 일치하지 않습니다.")

        temporary_path.replace(output_path)
        temporary_path = None
        return output_path

    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)

        close_body = getattr(body, "close", None)

        if callable(close_body):
            close_body()


# S3에 PNG 업로드 후 공개 URL 반환
def upload_file_to_s3(local_path: Path, s3_key: str) -> str:
    if not local_path.exists():
        raise FileNotFoundError(f"파일을 찾을 수 없습니다: {local_path}")

    if not S3_BUCKET:
        raise RuntimeError("S3_BUCKET 환경변수가 없습니다. .env를 확인하세요.")

    content_type, _ = mimetypes.guess_type(str(local_path))

    if content_type is None:
        content_type = "application/octet-stream"

    s3.upload_file(
        Filename=str(local_path),
        Bucket=S3_BUCKET,
        Key=s3_key,
        ExtraArgs={
            "ContentType": content_type,
        },
    )

    url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{s3_key}"
    return url

import re


MAX_JOB_NAME_LENGTH = 100
_SAFE_JOB_NAME_PATTERN = re.compile(r"^[\w-]+$", re.UNICODE)


def validate_job_name(name: str) -> str:
    if not isinstance(name, str) or not name:
        raise ValueError("name은 비어 있지 않은 문자열이어야 합니다.")

    if len(name) > MAX_JOB_NAME_LENGTH:
        raise ValueError(f"name은 {MAX_JOB_NAME_LENGTH}자 이하여야 합니다.")

    if _SAFE_JOB_NAME_PATTERN.fullmatch(name) is None:
        raise ValueError("name에는 문자, 숫자, 하이픈(-), 밑줄(_)만 사용할 수 있습니다.")

    return name

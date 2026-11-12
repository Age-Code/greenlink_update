import math


DEFAULT_WATER_DURATION_SECONDS = 30.0
MAX_WATER_DURATION_SECONDS = 30.0


def resolve_water_duration(command: dict) -> float:
    if "durationSeconds" not in command:
        return DEFAULT_WATER_DURATION_SECONDS

    value = command["durationSeconds"]

    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError("durationSeconds는 숫자여야 합니다.")

    duration_seconds = float(value)

    if not math.isfinite(duration_seconds):
        raise ValueError("durationSeconds는 유한한 숫자여야 합니다.")

    if duration_seconds <= 0 or duration_seconds > MAX_WATER_DURATION_SECONDS:
        raise ValueError(
            f"durationSeconds는 0초보다 크고 "
            f"{MAX_WATER_DURATION_SECONDS:g}초 이하여야 합니다."
        )

    return duration_seconds

package com.greenlink.greenlink.domain.automation;

// TriggerSensorType — 도메인 모델
public enum TriggerSensorType {

        // ESP 토양수분 센서값 기준

    SOIL_MOISTURE,

        // 라즈베리파이 조도 센서값 기준

    LIGHT,

        // 현재 시간이 조명 허용 시간대인지 여부 기준

    TIME,

        // 최근 자동화 실행 후 쿨다운 시간 기준

    COOLDOWN,

        // 이미 PENDING 또는 PROCESSING 상태의 명령이 있는 경우

    COMMAND_DUPLICATED,

        // 자동화 설정이 꺼져 있는 경우

    DISABLED,

        // 필요한 기기 또는 펌프 채널이 연결되어 있지 않은 경우

    DEVICE_NOT_READY,

        // 기타 사유

    ETC
}
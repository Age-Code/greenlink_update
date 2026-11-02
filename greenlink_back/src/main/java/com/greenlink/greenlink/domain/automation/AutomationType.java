package com.greenlink.greenlink.domain.automation;

// AutomationType — 도메인 모델
public enum AutomationType {

        // 자동 급수 명령 생성

    AUTO_WATER,

        // 자동 조명 켜기 명령 생성

    AUTO_LIGHT_ON,

        // 자동 조명 끄기 명령 생성

    AUTO_LIGHT_OFF,

        // 자동 급수 조건을 확인했지만 실행하지 않음

    SKIP_WATER,

        // 자동 조명 조건을 확인했지만 실행하지 않음

    SKIP_LIGHT
}
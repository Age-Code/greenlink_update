package com.greenlink.greenlink.domain.automation;

// AutomationModelStatus — 도메인 모델
public enum AutomationModelStatus {

        // 데이터가 부족해서 아직 학습 기준값을 사용할 수 없음

    INSUFFICIENT_DATA,

        // 학습 완료, 자동화 판단에 사용할 수 있음

    READY,

        // 학습 과정에서 오류 발생

    FAILED
}
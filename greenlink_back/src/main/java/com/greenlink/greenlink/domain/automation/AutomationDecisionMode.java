package com.greenlink.greenlink.domain.automation;

// AutomationDecisionMode — 도메인 모델
public enum AutomationDecisionMode {

        // 사용자가 설정한 고정 기준값만 사용

    RULE_BASED,

        // 학습 모델 기준값만 사용

    LEARNING_BASED,

        // 학습 모델이 충분하면 학습값 사용, — 부족하면 기본 규칙값 사용

    HYBRID
}
package com.greenlink.greenlink.domain.iot;

// CommandStatus — 도메인 모델
public enum CommandStatus {
    PENDING,
    PROCESSING,
    SUCCESS,
    FAILED,
    CANCELLED
}
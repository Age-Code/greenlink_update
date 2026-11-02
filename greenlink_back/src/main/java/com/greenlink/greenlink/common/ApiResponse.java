package com.greenlink.greenlink.common;

import lombok.Getter;

// ApiResponse — 공통 컴포넌트
@Getter
public class ApiResponse<T> {

    private final boolean success;
    private final String message;
    private final T data;

    // ApiResponse 생성
    private ApiResponse(boolean success, String message, T data) {
        this.success = success;
        this.message = message;
        this.data = data;
    }

    // AI 처리 성공 표시
    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(true, message, data);
    }

    // 실패 응답 생성
    public static <T> ApiResponse<T> fail(String message) {
        return new ApiResponse<>(false, message, null);
    }

    // 실패 응답 생성
    public static <T> ApiResponse<T> fail(String message, T data) {
        return new ApiResponse<>(false, message, data);
    }
}
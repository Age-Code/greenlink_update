package com.greenlink.greenlink.common;

// 요청이 너무 잦을 때 — GlobalExceptionHandler가 429로 응답한다.
public class TooManyRequestsException extends RuntimeException {

    public TooManyRequestsException(String message) {
        super(message);
    }
}

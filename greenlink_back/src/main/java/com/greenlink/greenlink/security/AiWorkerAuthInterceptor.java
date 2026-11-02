package com.greenlink.greenlink.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

// AI Worker 인증 인터셉터 — X-AI-Worker-Secret 헤더 검증, 불일치 시 401
@Component
public class AiWorkerAuthInterceptor implements HandlerInterceptor {

    private static final String AI_WORKER_SECRET_HEADER = "X-AI-Worker-Secret";

    private final String aiWorkerSecret;

    public AiWorkerAuthInterceptor(
            @Value("${greenlink.ai.worker-secret}") String aiWorkerSecret
    ) {
        this.aiWorkerSecret = aiWorkerSecret;
    }

    // AI Worker 요청 사전 검증 — X-AI-Worker-Secret 불일치 시 401
    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) throws Exception {
        String header = request.getHeader(AI_WORKER_SECRET_HEADER);

        if (!isValidSecret(header)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    "{\"success\":false,\"message\":\"AI Worker 인증에 실패했습니다.\",\"data\":null}"
            );
            return false;
        }

        return true;
    }

    // 상수 시간 비교 — 서버 secret이 비어 있으면 모든 요청 거부
    private boolean isValidSecret(String header) {
        if (header == null || aiWorkerSecret == null || aiWorkerSecret.isBlank()) {
            return false;
        }

        return MessageDigest.isEqual(
                header.getBytes(StandardCharsets.UTF_8),
                aiWorkerSecret.getBytes(StandardCharsets.UTF_8)
        );
    }
}

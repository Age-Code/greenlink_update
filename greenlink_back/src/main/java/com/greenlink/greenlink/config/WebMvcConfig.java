package com.greenlink.greenlink.config;

import com.greenlink.greenlink.security.AiWorkerAuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// MVC 설정 — /api/ai/** 에 AiWorkerAuthInterceptor 등록
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final AiWorkerAuthInterceptor aiWorkerAuthInterceptor;

    // 인터셉터 등록 — /api/ai/** callback secret 검증 적용
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(aiWorkerAuthInterceptor)
                .addPathPatterns("/api/ai/**");
    }
}

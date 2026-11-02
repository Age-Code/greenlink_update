package com.greenlink.greenlink.config;

import com.greenlink.greenlink.service.ImageStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.time.Duration;

// MVC 설정 — 서버 디스크에 저장한 식물 사진을 /images/** 로 제공
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final ImageStorageService imageStorageService;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 파일명에 시각·난수가 들어가 같은 경로의 내용이 바뀌지 않으므로 길게 캐시한다.
        registry.addResourceHandler(ImageStorageService.PUBLIC_PATH_PREFIX + "**")
                .addResourceLocations(imageStorageService.getRootDir().toUri().toString())
                .setCacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic());
    }
}

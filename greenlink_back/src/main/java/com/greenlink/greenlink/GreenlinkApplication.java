package com.greenlink.greenlink;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.TimeZone;

// GreenlinkApplication — GreenLink 백엔드 구성 요소
@SpringBootApplication
@EnableScheduling
public class GreenlinkApplication {

    // 애플리케이션 실행
    public static void main(String[] args) {
        // 출석·퀘스트 리셋·조명 시간대가 모두 LocalDate/LocalDateTime.now() 기준이므로 서버 OS 시간대와 무관하게 KST로 고정한다.
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));

        SpringApplication.run(GreenlinkApplication.class, args);
    }

}

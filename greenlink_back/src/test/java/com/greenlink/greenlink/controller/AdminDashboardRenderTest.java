package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.dto.AdminDto;
import com.greenlink.greenlink.service.AdminDashboardService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import static org.assertj.core.api.Assertions.assertThat;

// 관리자 대시보드 템플릿이 실제 집계 데이터로 렌더링되는지 확인한다.
@SpringBootTest
@ActiveProfiles("test")
class AdminDashboardRenderTest {

    @Autowired
    private AdminDashboardService adminDashboardService;
    @Autowired
    private TemplateEngine templateEngine;

    @Test
    void dashboardTemplateRendersWithRealData() {
        AdminDto.DashboardDto dashboard = adminDashboardService.getDashboard();

        Context context = new Context();
        context.setVariable("dashboard", dashboard);

        String html = templateEngine.process("admin/index", context);

        assertThat(html).contains("운영 현황");
        assertThat(html).contains("장치 연결 상태");
        assertThat(html).doesNotContain("Earnings");
    }
}

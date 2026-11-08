package com.greenlink.greenlink.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

// 관리자 웹 폼 — 잘못된 입력이 조용히 무시되지 않고 오류 메시지와 함께 폼으로 돌아오는지
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@WithMockUser(roles = "ADMIN")
class AdminWebFormTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void questFormWithoutRewardQuantityShowsValidationMessage() throws Exception {
        mockMvc.perform(post("/admin/quests")
                        .param("title", "물 주기")
                        .param("questType", "DAILY")
                        .param("targetType", "WATERING")
                        .param("targetValue", "1")
                        .param("resetCycle", "DAILY"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/quest/create"))
                .andExpect(model().attributeExists("errorMessage"));
    }

    @Test
    void plantFormWithNonNumericGrowthDaysShowsValidationMessage() throws Exception {
        mockMvc.perform(post("/admin/plants")
                        .param("name", "토마토")
                        .param("category", "VEGETABLE")
                        .param("growthDays", "abc"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/plant/create"))
                .andExpect(model().attributeExists("errorMessage"));
    }
}

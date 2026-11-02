package com.greenlink.greenlink.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityConfigTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(roles = "USER")
    void iotSetupApiIsForbiddenForNormalUser() throws Exception {
        mockMvc.perform(get("/api/iot/grow-spaces")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/iot/devices")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/iot/pump-channels")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void iotSetupApiIsAllowedForAdmin() throws Exception {
        mockMvc.perform(get("/api/iot/grow-spaces")).andExpect(status().isOk());
        mockMvc.perform(get("/api/iot/devices")).andExpect(status().isOk());
        mockMvc.perform(get("/api/iot/pump-channels")).andExpect(status().isOk());
    }

    @Test
    void deviceCollectionApiStaysOpenForDeviceKeyAuthentication() throws Exception {
        // 장치 키 검증은 Service가 담당하므로 Security 단계에서 막히면 안 된다.
        // 헤더가 없으면 인증 오류(401/403)가 아니라 필수 헤더 누락(400)이어야 한다.
        mockMvc.perform(get("/api/iot/commands/pending")).andExpect(status().isBadRequest());
    }
}

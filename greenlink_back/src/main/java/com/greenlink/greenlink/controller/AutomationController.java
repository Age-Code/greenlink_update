package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.AutomationDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.AutomationLearningService;
import com.greenlink.greenlink.service.AutomationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// AutomationController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-plants/{userPlantId}/automation")
public class AutomationController {

    private final AutomationService automationService;
    private final AutomationLearningService automationLearningService;

    // 자동화 설정 조회
    @GetMapping
    public ApiResponse<AutomationDto.SettingResDto> getSetting(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        AutomationDto.SettingResDto response =
                automationService.getSetting(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("자동화 설정 조회 성공", response);
    }

    // 자동화 설정 수정
    @PatchMapping
    public ApiResponse<AutomationDto.SettingResDto> updateSetting(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId,
            @RequestBody AutomationDto.UpdateSettingReqDto request
    ) {
        AutomationDto.SettingResDto response =
                automationService.updateSetting(
                        userDetails.getUserId(),
                        userPlantId,
                        request
                );

        return ApiResponse.success("자동화 설정 수정 성공", response);
    }

    // 자동화 로그 조회
    @GetMapping("/logs")
    public ApiResponse<List<AutomationDto.LogResDto>> getLogs(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        List<AutomationDto.LogResDto> response =
                automationService.getLogs(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("자동화 로그 조회 성공", response);
    }

    // 학습 모델 수동 실행
    @PostMapping("/train")
    public ApiResponse<AutomationDto.ModelResDto> trainModel(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        AutomationDto.ModelResDto response =
                automationLearningService.trainUserPlantModel(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("자동화 학습 모델 생성 성공", response);
    }

    // 최신 학습 모델 조회
    @GetMapping("/model")
    public ApiResponse<AutomationDto.ModelResDto> getLatestModel(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        AutomationDto.ModelResDto response =
                automationLearningService.getLatestModel(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("최신 자동화 학습 모델 조회 성공", response);
    }
}

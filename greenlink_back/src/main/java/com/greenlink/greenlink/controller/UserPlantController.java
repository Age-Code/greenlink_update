package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.dto.UserPlantDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.UserPlantService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// UserPlantController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-plants")
public class UserPlantController {

    private final UserPlantService userPlantService;

    // create User Plant 생성
    @PostMapping
    public ApiResponse<UserPlantDto.CreateResDto> createUserPlant(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserPlantDto.CreateReqDto request
    ) {
        UserPlantDto.CreateResDto response = userPlantService.createUserPlant(
                userDetails.getUserId(),
                request
        );

        return ApiResponse.success("식물이 생성되었습니다.", response);
    }

    @GetMapping
    public ApiResponse<List<UserPlantDto.ListResDto>> getUserPlants(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(required = false) UserPlantStatus status
    ) {
        List<UserPlantDto.ListResDto> response = userPlantService.getUserPlants(
                userDetails.getUserId(),
                status
        );

        return ApiResponse.success("내 식물 목록 조회 성공", response);
    }

    @GetMapping("/{userPlantId}")
    public ApiResponse<UserPlantDto.DetailResDto> getUserPlant(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        UserPlantDto.DetailResDto response = userPlantService.getUserPlant(
                userDetails.getUserId(),
                userPlantId
        );

        return ApiResponse.success("내 식물 상세 조회 성공", response);
    }

    // update Nickname 수정
    @PatchMapping("/{userPlantId}")
    public ApiResponse<UserPlantDto.UpdateNicknameResDto> updateNickname(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId,
            @Valid @RequestBody UserPlantDto.UpdateNicknameReqDto request
    ) {
        UserPlantDto.UpdateNicknameResDto response = userPlantService.updateNickname(
                userDetails.getUserId(),
                userPlantId,
                request
        );

        return ApiResponse.success("식물 이름이 수정되었습니다.", response);
    }

    // 수확 처리 — HARVEST/GROW_PLANT 퀘스트 진행 증가
    @PostMapping("/{userPlantId}/harvest")
    public ApiResponse<UserPlantDto.HarvestResDto> harvestUserPlant(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        UserPlantDto.HarvestResDto response = userPlantService.harvestUserPlant(
                userDetails.getUserId(),
                userPlantId
        );

        return ApiResponse.success("식물 수확이 완료되었습니다.", response);
    }
}

package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.domain.item.UserItemStatus;
import com.greenlink.greenlink.dto.UserItemDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.UserItemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// UserItemController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-items")
public class UserItemController {

    private final UserItemService userItemService;

    @GetMapping
    public ApiResponse<List<UserItemDto.ListResDto>> getUserItems(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(required = false) ItemType itemType,
            @RequestParam(required = false) UserItemStatus status
    ) {
        List<UserItemDto.ListResDto> response = userItemService.getUserItems(
                userDetails.getUserId(),
                itemType,
                status
        );

        return ApiResponse.success("내 아이템 조회 성공", response);
    }

    // 화분 장착 처리
    @PostMapping("/{userItemId}/equip-pot")
    public ApiResponse<UserItemDto.EquipPotResDto> equipPot(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userItemId,
            @Valid @RequestBody UserItemDto.EquipPotReqDto request
    ) {
        UserItemDto.EquipPotResDto response = userItemService.equipPot(
                userDetails.getUserId(),
                userItemId,
                request
        );

        return ApiResponse.success("화분이 장착되었습니다.", response);
    }

    // 화분 해제 처리
    @PostMapping("/{userItemId}/unequip-pot")
    public ApiResponse<UserItemDto.UnequipPotResDto> unequipPot(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userItemId
    ) {
        UserItemDto.UnequipPotResDto response = userItemService.unequipPot(
                userDetails.getUserId(),
                userItemId
        );

        return ApiResponse.success("화분 장착이 해제되었습니다.", response);
    }

    // 영양제 사용 처리
    @PostMapping("/{userItemId}/use-nutrient")
    public ApiResponse<UserItemDto.UseNutrientResDto> useNutrient(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userItemId,
            @Valid @RequestBody UserItemDto.UseNutrientReqDto request
    ) {
        UserItemDto.UseNutrientResDto response = userItemService.useNutrient(
                userDetails.getUserId(),
                userItemId,
                request
        );

        return ApiResponse.success("영양제를 사용했습니다.", response);
    }
}

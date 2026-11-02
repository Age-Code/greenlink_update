package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.AdminDto;
import com.greenlink.greenlink.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

// 관리자 REST Controller — 마스터 데이터 생성
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;

    // create Plant 생성
    @PostMapping("/plants")
    public ApiResponse<AdminDto.PlantResDto> createPlant(
            @Valid @RequestBody AdminDto.CreatePlantReqDto request
    ) {
        AdminDto.PlantResDto response = adminService.createPlant(request);

        return ApiResponse.success("식물이 등록되었습니다.", response);
    }

    // create Item 생성
    @PostMapping("/items")
    public ApiResponse<AdminDto.ItemResDto> createItem(
            @Valid @RequestBody AdminDto.CreateItemReqDto request
    ) {
        AdminDto.ItemResDto response = adminService.createItem(request);

        return ApiResponse.success("아이템이 등록되었습니다.", response);
    }

    // create Quest 생성
    @PostMapping("/quests")
    public ApiResponse<AdminDto.QuestResDto> createQuest(
            @Valid @RequestBody AdminDto.CreateQuestReqDto request
    ) {
        AdminDto.QuestResDto response = adminService.createQuest(request);

        return ApiResponse.success("퀘스트가 등록되었습니다.", response);
    }
}

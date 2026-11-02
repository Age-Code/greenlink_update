package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.PlantDto;
import com.greenlink.greenlink.service.PlantService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// PlantController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/plants")
public class PlantController {

    private final PlantService plantService;

    @GetMapping
    public ApiResponse<List<PlantDto.ListResDto>> getPlants() {
        List<PlantDto.ListResDto> response = plantService.getPlants();

        return ApiResponse.success("식물 목록 조회 성공", response);
    }

    @GetMapping("/{plantId}")
    public ApiResponse<PlantDto.DetailResDto> getPlant(
            @PathVariable Long plantId
    ) {
        PlantDto.DetailResDto response = plantService.getPlant(plantId);

        return ApiResponse.success("식물 상세 조회 성공", response);
    }
}
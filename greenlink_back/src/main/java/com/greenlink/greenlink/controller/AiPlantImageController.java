package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.ai.AiPlantImageDto;
import com.greenlink.greenlink.service.AiPlantImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

// AiPlantImageController — API 요청 처리
@RestController
@RequestMapping("/api/ai/plant-images")
@RequiredArgsConstructor
public class AiPlantImageController {

    private final AiPlantImageService aiPlantImageService;

    // AI 변환 결과 저장
    @PostMapping("/{plantImageId}/result")
    public ApiResponse<AiPlantImageDto.AiImageResDto> saveAiImageResult(
            @PathVariable Long plantImageId,
            @RequestBody AiPlantImageDto.SaveAiImageReqDto request
    ) {
        AiPlantImageDto.AiImageResDto response =
                aiPlantImageService.saveAiImageResult(
                        plantImageId,
                        request
                );

        return ApiResponse.success("AI 식물 이미지 결과가 저장되었습니다.", response);
    }
}

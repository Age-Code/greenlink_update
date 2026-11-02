package com.greenlink.greenlink.dto.ai;

import com.greenlink.greenlink.domain.ai.AiImageStatus;
import com.greenlink.greenlink.domain.ai.AiPlantImage;
import lombok.*;

import java.time.LocalDateTime;

// AiPlantImageDto — API 요청/응답 DTO
public class AiPlantImageDto {

    // SaveAiImageReqDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SaveAiImageReqDto {
        private String finalAiUrl;
    }

    // AiImageResDto DTO — API 요청/응답 데이터
    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AiImageResDto {
        private Long aiPlantImageId;
        private Long plantImageId;
        private Long userPlantId;
        private String originalImageUrl;
        private String aiImageUrl;
        private AiImageStatus status;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static AiImageResDto from(AiPlantImage aiPlantImage) {
            return AiImageResDto.builder()
                    .aiPlantImageId(aiPlantImage.getId())
                    .plantImageId(aiPlantImage.getPlantImage().getId())
                    .userPlantId(aiPlantImage.getUserPlant().getId())
                    .originalImageUrl(aiPlantImage.getOriginalImageUrl())
                    .aiImageUrl(aiPlantImage.getAiImageUrl())
                    .status(aiPlantImage.getStatus())
                    .createdAt(aiPlantImage.getCreatedAt())
                    .build();
        }
    }
}
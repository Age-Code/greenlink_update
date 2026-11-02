package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.plant.Plant;
import lombok.*;

// PlantDto — API 요청/응답 DTO
public class PlantDto {

    // ListResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResDto {
        private Long plantId;
        private String name;
        private String category;
        private String imageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto from(Plant plant) {
            return ListResDto.builder()
                    .plantId(plant.getId())
                    .name(plant.getName())
                    .category(plant.getCategory())
                    .imageUrl(plant.getImageUrl())
                    .build();
        }
    }

    // DetailResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DetailResDto {
        private Long plantId;
        private String name;
        private String category;
        private String description;
        private String imageUrl;
        private Integer growthDays;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto from(Plant plant) {
            return DetailResDto.builder()
                    .plantId(plant.getId())
                    .name(plant.getName())
                    .category(plant.getCategory())
                    .description(plant.getDescription())
                    .imageUrl(plant.getImageUrl())
                    .growthDays(plant.getGrowthDays())
                    .build();
        }
    }
}
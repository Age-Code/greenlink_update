package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

// CollectionDto — API 요청/응답 DTO
public class CollectionDto {

    // 도감 목록 응답 DTO
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

        private boolean collected;
        private long harvestCount;
        private LocalDateTime firstHarvestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto of(
                Plant plant,
                boolean collected,
                long harvestCount,
                LocalDateTime firstHarvestedAt
        ) {
            return ListResDto.builder()
                    .plantId(plant.getId())
                    .name(plant.getName())
                    .category(plant.getCategory())
                    .imageUrl(plant.getImageUrl())
                    .collected(collected)
                    .harvestCount(harvestCount)
                    .firstHarvestedAt(firstHarvestedAt)
                    .build();
        }
    }

    // 도감 상세에 포함되는 수확 식물 DTO — 사용자가 실제로 수확한 user_plant 목록입니다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HarvestedPlantDto {
        private Long userPlantId;
        private String nickname;
        private String imageUrl;
        private LocalDateTime plantedAt;
        private LocalDateTime harvestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static HarvestedPlantDto from(UserPlant userPlant) {
            return HarvestedPlantDto.builder()
                    .userPlantId(userPlant.getId())
                    .nickname(userPlant.getNickname())
                    .imageUrl(userPlant.getImageUrl())
                    .plantedAt(userPlant.getPlantedAt())
                    .harvestedAt(userPlant.getHarvestedAt())
                    .build();
        }
    }

    // 도감 상세 응답 DTO
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

        private boolean collected;
        private long harvestCount;
        private List<HarvestedPlantDto> harvestedPlants;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto of(
                Plant plant,
                List<UserPlant> harvestedPlants
        ) {
            return DetailResDto.builder()
                    .plantId(plant.getId())
                    .name(plant.getName())
                    .category(plant.getCategory())
                    .description(plant.getDescription())
                    .imageUrl(plant.getImageUrl())
                    .collected(!harvestedPlants.isEmpty())
                    .harvestCount(harvestedPlants.size())
                    .harvestedPlants(
                            harvestedPlants.stream()
                                    .map(HarvestedPlantDto::from)
                                    .toList()
                    )
                    .build();
        }
    }
}

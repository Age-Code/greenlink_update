package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.Item;
import lombok.*;

// ItemDto — API 요청/응답 DTO
public class ItemDto {

    // ListResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResDto {
        private Long itemId;
        private String name;
        private String itemType;
        private String imageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto from(Item item) {
            return ListResDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .itemType(item.getItemType().name())
                    .imageUrl(item.getImageUrl())
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
        private Long itemId;
        private String name;
        private String itemType;
        private String description;
        private String imageUrl;
        private Long linkedPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto from(Item item) {
            Long linkedPlantId = item.getLinkedPlant() == null
                    ? null
                    : item.getLinkedPlant().getId();

            return DetailResDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .itemType(item.getItemType().name())
                    .description(item.getDescription())
                    .imageUrl(item.getImageUrl())
                    .linkedPlantId(linkedPlantId)
                    .build();
        }
    }
}
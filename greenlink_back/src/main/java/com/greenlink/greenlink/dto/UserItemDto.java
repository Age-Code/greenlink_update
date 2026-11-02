package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

// UserItemDto — API 요청/응답 DTO
public class UserItemDto {

    // 내 보유 아이템 목록 응답 DTO — item 단위로 묶어서 내려주는 DTO입니다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResDto {
        private Long itemId;
        private String name;
        private String itemType;
        private String description;
        private String imageUrl;
        private Long linkedPlantId;

        private long ownedCount;
        private long usableCount;
        private long usedCount;

        private List<DetailResDto> items;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto of(
                Item item,
                long ownedCount,
                long usableCount,
                long usedCount,
                List<UserItem> userItems
        ) {
            Long linkedPlantId = item.getLinkedPlant() == null
                    ? null
                    : item.getLinkedPlant().getId();

            return ListResDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .itemType(item.getItemType().name())
                    .description(item.getDescription())
                    .imageUrl(item.getImageUrl())
                    .linkedPlantId(linkedPlantId)
                    .ownedCount(ownedCount)
                    .usableCount(usableCount)
                    .usedCount(usedCount)
                    .items(
                            userItems.stream()
                                    .map(DetailResDto::from)
                                    .toList()
                    )
                    .build();
        }
    }

    // 개별 user_item row 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DetailResDto {
        private Long userItemId;
        private String status;
        private Long userPlantId;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto from(UserItem userItem) {
            Long userPlantId = userItem.getUserPlant() == null
                    ? null
                    : userItem.getUserPlant().getId();

            return DetailResDto.builder()
                    .userItemId(userItem.getId())
                    .status(userItem.getStatus().name())
                    .userPlantId(userPlantId)
                    .createdAt(userItem.getCreatedAt())
                    .build();
        }
    }

    // 화분 장착 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EquipPotReqDto {

        @NotNull(message = "장착할 식물 ID는 필수입니다.")
        private Long userPlantId;
    }

    // 화분 장착 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EquipPotResDto {
        private Long userItemId;
        private Long itemId;
        private String itemName;
        private String itemType;
        private String status;
        private Long userPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static EquipPotResDto from(UserItem userItem) {
            Long userPlantId = userItem.getUserPlant() == null
                    ? null
                    : userItem.getUserPlant().getId();

            return EquipPotResDto.builder()
                    .userItemId(userItem.getId())
                    .itemId(userItem.getItem().getId())
                    .itemName(userItem.getItem().getName())
                    .itemType(userItem.getItem().getItemType().name())
                    .status(userItem.getStatus().name())
                    .userPlantId(userPlantId)
                    .build();
        }
    }

    // 화분 장착 해제 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UnequipPotResDto {
        private Long userItemId;
        private String status;
        private Long userPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UnequipPotResDto from(UserItem userItem) {
            Long userPlantId = userItem.getUserPlant() == null
                    ? null
                    : userItem.getUserPlant().getId();

            return UnequipPotResDto.builder()
                    .userItemId(userItem.getId())
                    .status(userItem.getStatus().name())
                    .userPlantId(userPlantId)
                    .build();
        }
    }

    // 영양제 사용 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UseNutrientReqDto {

        @NotNull(message = "영양제를 사용할 식물 ID는 필수입니다.")
        private Long userPlantId;
    }

    // 영양제 사용 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UseNutrientResDto {
        private Long userItemId;
        private String itemType;
        private String status;
        private Long userPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UseNutrientResDto from(UserItem userItem) {
            Long userPlantId = userItem.getUserPlant() == null
                    ? null
                    : userItem.getUserPlant().getId();

            return UseNutrientResDto.builder()
                    .userItemId(userItem.getId())
                    .itemType(userItem.getItem().getItemType().name())
                    .status(userItem.getStatus().name())
                    .userPlantId(userPlantId)
                    .build();
        }
    }
}

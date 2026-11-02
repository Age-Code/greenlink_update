package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

// UserPlantDto — API 요청/응답 DTO
public class UserPlantDto {

    // 내 식물 생성 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateReqDto {

        @NotNull(message = "사용할 씨앗 아이템 ID는 필수입니다.")
        private Long userItemId;

        @Size(max = 50, message = "식물 이름은 50자 이하로 입력해야 합니다.")
        private String nickname;
    }

    // 내 식물 생성 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateResDto {
        private Long userPlantId;
        private Long plantId;
        private String plantName;
        private String nickname;
        private String status;
        private LocalDateTime plantedAt;
        private LocalDateTime expectedHarvestableAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static CreateResDto from(UserPlant userPlant) {
            LocalDateTime expectedHarvestableAt = userPlant.getPlantedAt()
                    .plusDays(userPlant.getPlant().getGrowthDays());

            return CreateResDto.builder()
                    .userPlantId(userPlant.getId())
                    .plantId(userPlant.getPlant().getId())
                    .plantName(userPlant.getPlant().getName())
                    .nickname(userPlant.getNickname())
                    .status(userPlant.getStatus().name())
                    .plantedAt(userPlant.getPlantedAt())
                    .expectedHarvestableAt(expectedHarvestableAt)
                    .build();
        }
    }

    // 내 식물 목록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResDto {
        private Long userPlantId;
        private Long plantId;
        private String plantName;
        private String nickname;
        private String status;
        private LocalDateTime plantedAt;
        private long daysAfterPlanting;
        private long remainingDays;
        private String imageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto from(UserPlant userPlant, LocalDate today) {
            return ListResDto.builder()
                    .userPlantId(userPlant.getId())
                    .plantId(userPlant.getPlant().getId())
                    .plantName(userPlant.getPlant().getName())
                    .nickname(userPlant.getNickname())
                    .status(userPlant.getStatus().name())
                    .plantedAt(userPlant.getPlantedAt())
                    .daysAfterPlanting(userPlant.getDaysAfterPlanting(today))
                    .remainingDays(userPlant.getRemainingDays(today))
                    .imageUrl(userPlant.getImageUrl())
                    .build();
        }
    }

    // 장착 화분 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EquippedPotDto {
        private Long userItemId;
        private Long itemId;
        private String name;
        private String imageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static EquippedPotDto from(UserItem userItem) {
            return EquippedPotDto.builder()
                    .userItemId(userItem.getId())
                    .itemId(userItem.getItem().getId())
                    .name(userItem.getItem().getName())
                    .imageUrl(userItem.getItem().getImageUrl())
                    .build();
        }
    }

    // 내 식물 상세 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DetailResDto {
        private Long userPlantId;
        private Long plantId;
        private String plantName;
        private String nickname;
        private String imageUrl;
        private String status;
        private LocalDateTime plantedAt;
        private LocalDateTime harvestedAt;
        private long daysAfterPlanting;
        private long remainingDays;
        private EquippedPotDto equippedPot;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto of(
                UserPlant userPlant,
                LocalDate today,
                UserItem equippedPot
        ) {
            return DetailResDto.builder()
                    .userPlantId(userPlant.getId())
                    .plantId(userPlant.getPlant().getId())
                    .plantName(userPlant.getPlant().getName())
                    .nickname(userPlant.getNickname())
                    .imageUrl(userPlant.getImageUrl())
                    .status(userPlant.getStatus().name())
                    .plantedAt(userPlant.getPlantedAt())
                    .harvestedAt(userPlant.getHarvestedAt())
                    .daysAfterPlanting(userPlant.getDaysAfterPlanting(today))
                    .remainingDays(userPlant.getRemainingDays(today))
                    .equippedPot(equippedPot == null ? null : EquippedPotDto.from(equippedPot))
                    .build();
        }
    }

    // 식물 이름 수정 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateNicknameReqDto {

        @Size(max = 50, message = "식물 이름은 50자 이하로 입력해야 합니다.")
        private String nickname;
    }

    // 식물 이름 수정 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateNicknameResDto {
        private Long userPlantId;
        private String nickname;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UpdateNicknameResDto from(UserPlant userPlant) {
            return UpdateNicknameResDto.builder()
                    .userPlantId(userPlant.getId())
                    .nickname(userPlant.getNickname())
                    .build();
        }
    }

    // 식물 수확 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HarvestResDto {
        private Long userPlantId;
        private Long plantId;
        private String plantName;
        private String status;
        private LocalDateTime harvestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static HarvestResDto from(UserPlant userPlant) {
            return HarvestResDto.builder()
                    .userPlantId(userPlant.getId())
                    .plantId(userPlant.getPlant().getId())
                    .plantName(userPlant.getPlant().getName())
                    .status(userPlant.getStatus().name())
                    .harvestedAt(userPlant.getHarvestedAt())
                    .build();
        }
    }
}

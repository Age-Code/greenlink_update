package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.ResetCycle;
import com.greenlink.greenlink.domain.quest.TargetType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

// AdminDto — API 요청/응답 DTO
public class AdminDto {

    // 관리자 식물 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreatePlantReqDto {

        @NotBlank(message = "식물 이름은 필수입니다.")
        private String name;

        @NotBlank(message = "식물 카테고리는 필수입니다.")
        private String category;

        private String description;

        private String imageUrl;

        @NotNull(message = "성장 일수는 필수입니다.")
        @Min(value = 1, message = "성장 일수는 1일 이상이어야 합니다.")
        private Integer growthDays;
    }

    // 관리자 식물 등록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PlantResDto {
        private Long plantId;
        private String name;
        private String category;
        private String description;
        private String imageUrl;
        private Integer growthDays;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PlantResDto from(Plant plant) {
            return PlantResDto.builder()
                    .plantId(plant.getId())
                    .name(plant.getName())
                    .category(plant.getCategory())
                    .description(plant.getDescription())
                    .imageUrl(plant.getImageUrl())
                    .growthDays(plant.getGrowthDays())
                    .build();
        }
    }

    // 관리자 아이템 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateItemReqDto {

        @NotBlank(message = "아이템 이름은 필수입니다.")
        private String name;

        @NotNull(message = "아이템 타입은 필수입니다.")
        private ItemType itemType;

        private String description;

        private String imageUrl;

        private Long linkedPlantId;
    }

    // 관리자 아이템 등록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemResDto {
        private Long itemId;
        private String name;
        private ItemType itemType;
        private String description;
        private String imageUrl;
        private Long linkedPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ItemResDto from(Item item) {
            Long linkedPlantId = item.getLinkedPlant() == null
                    ? null
                    : item.getLinkedPlant().getId();

            return ItemResDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .itemType(item.getItemType())
                    .description(item.getDescription())
                    .imageUrl(item.getImageUrl())
                    .linkedPlantId(linkedPlantId)
                    .build();
        }
    }

    // 관리자 퀘스트 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateQuestReqDto {

        @NotBlank(message = "퀘스트 제목은 필수입니다.")
        private String title;

        private String description;

        @NotNull(message = "퀘스트 타입은 필수입니다.")
        private QuestType questType;

        @NotNull(message = "목표 타입은 필수입니다.")
        private TargetType targetType;

        @NotNull(message = "목표 수치는 필수입니다.")
        @Min(value = 1, message = "목표 수치는 1 이상이어야 합니다.")
        private Integer targetValue;

        private Long rewardItemId;

        @NotNull(message = "보상 수량은 필수입니다.")
        @Min(value = 0, message = "보상 수량은 0 이상이어야 합니다.")
        private Integer rewardQuantity;

        @NotNull(message = "반복 주기는 필수입니다.")
        private ResetCycle resetCycle;
    }

    // 관리자 퀘스트 등록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestResDto {
        private Long questId;
        private String title;
        private String description;
        private QuestType questType;
        private TargetType targetType;
        private Integer targetValue;
        private Long rewardItemId;
        private String rewardItemName;
        private Integer rewardQuantity;
        private ResetCycle resetCycle;
        private Boolean active;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static QuestResDto from(Quest quest) {
            Long rewardItemId = quest.getRewardItem() == null
                    ? null
                    : quest.getRewardItem().getId();

            String rewardItemName = quest.getRewardItem() == null
                    ? null
                    : quest.getRewardItem().getName();

            return QuestResDto.builder()
                    .questId(quest.getId())
                    .title(quest.getTitle())
                    .description(quest.getDescription())
                    .questType(quest.getQuestType())
                    .targetType(quest.getTargetType())
                    .targetValue(quest.getTargetValue())
                    .rewardItemId(rewardItemId)
                    .rewardItemName(rewardItemName)
                    .rewardQuantity(quest.getRewardQuantity())
                    .resetCycle(quest.getResetCycle())
                    .active(quest.getActive())
                    .build();
        }
    }

    // 관리자 IoT 기기 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateIotDeviceReqDto {
        @NotBlank(message = "기기 이름은 필수입니다.")
        private String deviceName;

        @NotNull(message = "기기 타입은 필수입니다.")
        private com.greenlink.greenlink.domain.iot.DeviceType deviceType;

        @NotBlank(message = "기기 고유 키는 필수입니다.")
        private String deviceKey;

        private Long growSpaceId;
        private Long userPlantId;
    }

    // 관리자 IoT 기기 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class IotDeviceResDto {
        private Long deviceId;
        private String deviceName;
        private com.greenlink.greenlink.domain.iot.DeviceType deviceType;
        private Boolean active;
        private Long growSpaceId;
        private Long userPlantId;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static IotDeviceResDto from(com.greenlink.greenlink.domain.iot.IotDevice iotDevice) {
            Long growSpaceId = iotDevice.getGrowSpace() == null ? null : iotDevice.getGrowSpace().getId();
            Long userPlantId = iotDevice.getUserPlant() == null ? null : iotDevice.getUserPlant().getId();

            return IotDeviceResDto.builder()
                    .deviceId(iotDevice.getId())
                    .deviceName(iotDevice.getDeviceName())
                    .deviceType(iotDevice.getDeviceType())
                    .active(iotDevice.getActive())
                    .growSpaceId(growSpaceId)
                    .userPlantId(userPlantId)
                    .build();
        }
    }
}

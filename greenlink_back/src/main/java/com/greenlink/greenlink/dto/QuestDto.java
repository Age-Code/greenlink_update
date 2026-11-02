package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.UserQuest;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

// QuestDto — API 요청/응답 DTO
public class QuestDto {

    // 퀘스트 보상 아이템 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RewardItemDto {
        private Long itemId;
        private String name;
        private String itemType;
        private String imageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static RewardItemDto from(Item item) {
            if (item == null) {
                return null;
            }

            return RewardItemDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .itemType(item.getItemType().name())
                    .imageUrl(item.getImageUrl())
                    .build();
        }
    }

    // 퀘스트 목록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResDto {
        private Long questId;
        private String title;
        private String questType;
        private String targetType;
        private Integer targetValue;
        private String resetCycle;
        private Boolean active;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ListResDto from(Quest quest) {
            return ListResDto.builder()
                    .questId(quest.getId())
                    .title(quest.getTitle())
                    .questType(quest.getQuestType().name())
                    .targetType(quest.getTargetType().name())
                    .targetValue(quest.getTargetValue())
                    .resetCycle(quest.getResetCycle().name())
                    .active(quest.getActive())
                    .build();
        }
    }

    // 퀘스트 상세 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DetailResDto {
        private Long questId;
        private String title;
        private String description;
        private String questType;
        private String targetType;
        private Integer targetValue;
        private RewardItemDto rewardItem;
        private Integer rewardQuantity;
        private String resetCycle;
        private Boolean active;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DetailResDto from(Quest quest) {
            return DetailResDto.builder()
                    .questId(quest.getId())
                    .title(quest.getTitle())
                    .description(quest.getDescription())
                    .questType(quest.getQuestType().name())
                    .targetType(quest.getTargetType().name())
                    .targetValue(quest.getTargetValue())
                    .rewardItem(RewardItemDto.from(quest.getRewardItem()))
                    .rewardQuantity(quest.getRewardQuantity())
                    .resetCycle(quest.getResetCycle().name())
                    .active(quest.getActive())
                    .build();
        }
    }

    // 내 퀘스트 목록 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserQuestListResDto {
        private Long userQuestId;
        private Long questId;
        private String title;
        private String questType;
        private String targetType;
        private Integer targetValue;
        private Integer progressValue;
        private String status;
        private LocalDateTime startedAt;
        private LocalDateTime expiredAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UserQuestListResDto from(UserQuest userQuest) {
            return UserQuestListResDto.builder()
                    .userQuestId(userQuest.getId())
                    .questId(userQuest.getQuest().getId())
                    .title(userQuest.getQuest().getTitle())
                    .questType(userQuest.getQuest().getQuestType().name())
                    .targetType(userQuest.getQuest().getTargetType().name())
                    .targetValue(userQuest.getQuest().getTargetValue())
                    .progressValue(userQuest.getProgressValue())
                    .status(userQuest.getStatus().name())
                    .startedAt(userQuest.getStartedAt())
                    .expiredAt(userQuest.getExpiredAt())
                    .build();
        }
    }

    // 내 퀘스트 상세 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserQuestDetailResDto {
        private Long userQuestId;
        private Long questId;
        private String title;
        private String description;
        private String questType;
        private String targetType;
        private Integer targetValue;
        private Integer progressValue;
        private String status;
        private LocalDateTime startedAt;
        private LocalDateTime expiredAt;
        private LocalDateTime createdAt;
        private LocalDateTime modifiedAt;
        private RewardItemDto rewardItem;
        private Integer rewardQuantity;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UserQuestDetailResDto from(UserQuest userQuest) {
            Quest quest = userQuest.getQuest();

            return UserQuestDetailResDto.builder()
                    .userQuestId(userQuest.getId())
                    .questId(quest.getId())
                    .title(quest.getTitle())
                    .description(quest.getDescription())
                    .questType(quest.getQuestType().name())
                    .targetType(quest.getTargetType().name())
                    .targetValue(quest.getTargetValue())
                    .progressValue(userQuest.getProgressValue())
                    .status(userQuest.getStatus().name())
                    .startedAt(userQuest.getStartedAt())
                    .expiredAt(userQuest.getExpiredAt())
                    .createdAt(userQuest.getCreatedAt())
                    .modifiedAt(userQuest.getModifiedAt())
                    .rewardItem(RewardItemDto.from(quest.getRewardItem()))
                    .rewardQuantity(quest.getRewardQuantity())
                    .build();
        }
    }

    // 퀘스트 보상 수령 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserQuestRewardResDto {
        private Long userQuestId;
        private String status;
        private RewardResDto reward;
        private List<CreatedUserItemDto> createdUserItems;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UserQuestRewardResDto of(
                UserQuest userQuest,
                Item rewardItem,
                Integer quantity,
                List<UserItem> createdUserItems
        ) {
            return UserQuestRewardResDto.builder()
                    .userQuestId(userQuest.getId())
                    .status(userQuest.getStatus().name())
                    .reward(RewardResDto.of(rewardItem, quantity))
                    .createdUserItems(
                            createdUserItems.stream()
                                    .map(CreatedUserItemDto::from)
                                    .toList()
                    )
                    .build();
        }
    }

    // 보상 정보 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RewardResDto {
        private Long itemId;
        private String itemName;
        private String itemType;
        private Integer quantity;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static RewardResDto of(Item item, Integer quantity) {
            if (item == null) {
                return null;
            }

            return RewardResDto.builder()
                    .itemId(item.getId())
                    .itemName(item.getName())
                    .itemType(item.getItemType().name())
                    .quantity(quantity)
                    .build();
        }
    }

    // 보상 수령으로 생성된 user_item DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreatedUserItemDto {
        private Long userItemId;
        private Long itemId;
        private String status;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static CreatedUserItemDto from(UserItem userItem) {
            return CreatedUserItemDto.builder()
                    .userItemId(userItem.getId())
                    .itemId(userItem.getItem().getId())
                    .status(userItem.getStatus().name())
                    .build();
        }
    }
}

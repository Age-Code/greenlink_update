package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

// HomeDto — API 요청/응답 DTO
public class HomeDto {

    // 홈 화면 전체 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResDto {
        private UserDto user;
        private UserPlantDto mainUserPlant;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ResDto of(
                User user,
                UserPlant mainUserPlant,
                LocalDate today
        ) {
            return ResDto.builder()
                    .user(UserDto.from(user))
                    .mainUserPlant(UserPlantDto.from(mainUserPlant, today))
                    .build();
        }
    }

    // 홈 화면 사용자 정보 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserDto {
        private Long userId;
        private String nickname;
        private String profileImageUrl;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UserDto from(User user) {
            return UserDto.builder()
                    .userId(user.getId())
                    .nickname(user.getNickname())
                    .profileImageUrl(user.getProfileImageUrl())
                    .build();
        }
    }

    // 홈 화면 대표 식물 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserPlantDto {
        private Long userPlantId;
        private Long plantId;
        private String plantName;
        private String nickname;
        private String status;
        private String imageUrl;
        private LocalDateTime plantedAt;
        private long daysAfterPlanting;
        private long remainingDays;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UserPlantDto from(UserPlant userPlant, LocalDate today) {
            if (userPlant == null) {
                return null;
            }

            return UserPlantDto.builder()
                    .userPlantId(userPlant.getId())
                    .plantId(userPlant.getPlant().getId())
                    .plantName(userPlant.getPlant().getName())
                    .nickname(userPlant.getNickname())
                    .status(userPlant.getStatus().name())
                    .imageUrl(userPlant.getImageUrl())
                    .plantedAt(userPlant.getPlantedAt())
                    .daysAfterPlanting(userPlant.getDaysAfterPlanting(today))
                    .remainingDays(userPlant.getRemainingDays(today))
                    .build();
        }
    }
}

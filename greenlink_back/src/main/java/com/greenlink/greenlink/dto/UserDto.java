package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.user.User;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.time.LocalDateTime;

// UserDto — API 요청/응답 DTO
public class UserDto {

    // MeResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MeResDto {
        private Long userId;
        private String email;
        private String nickname;
        private String role;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static MeResDto from(User user) {
            return MeResDto.builder()
                    .userId(user.getId())
                    .email(user.getEmail())
                    .nickname(user.getNickname())
                    .role(user.getRole().name())
                    .createdAt(user.getCreatedAt())
                    .build();
        }
    }

    // UpdateNicknameReqDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateNicknameReqDto {

        @NotBlank(message = "닉네임은 필수입니다.")
        @Size(max = 50, message = "닉네임은 50자 이하로 입력해야 합니다.")
        private String nickname;
    }

    // ChangePasswordReqDto DTO — 현재 비밀번호 검증 후 새 비밀번호로 변경
    @Getter
    @Setter
    @NoArgsConstructor
    public static class ChangePasswordReqDto {

        @NotBlank(message = "현재 비밀번호는 필수입니다.")
        private String currentPassword;

        @NotBlank(message = "새 비밀번호는 필수입니다.")
        @Size(min = 4, message = "새 비밀번호는 4자 이상이어야 합니다.")
        private String newPassword;
    }

    // UpdateNicknameResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateNicknameResDto {
        private Long userId;
        private String nickname;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static UpdateNicknameResDto from(User user) {
            return UpdateNicknameResDto.builder()
                    .userId(user.getId())
                    .nickname(user.getNickname())
                    .build();
        }
    }
}

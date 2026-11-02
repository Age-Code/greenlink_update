package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.user.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.List;

// AuthDto — API 요청/응답 DTO
public class AuthDto {

    // 회원가입 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SignupReqDto {

        @NotBlank(message = "이메일은 필수입니다.")
        @Email(message = "올바른 이메일 형식이 아닙니다.")
        private String email;

        @NotBlank(message = "비밀번호는 필수입니다.")
        @Size(min = 4, message = "비밀번호는 4자 이상이어야 합니다.")
        private String password;

        @NotBlank(message = "닉네임은 필수입니다.")
        @Size(max = 50, message = "닉네임은 50자 이하로 입력해야 합니다.")
        private String nickname;
    }

    // 회원가입 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SignupResDto {
        private Long userId;
        private String email;
        private String nickname;
        private List<GrantedItemDto> grantedItems;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static SignupResDto of(User user, List<UserItem> grantedUserItems) {
            return SignupResDto.builder()
                    .userId(user.getId())
                    .email(user.getEmail())
                    .nickname(user.getNickname())
                    .grantedItems(
                            grantedUserItems.stream()
                                    .map(GrantedItemDto::from)
                                    .toList()
                    )
                    .build();
        }
    }

    // 회원가입 시 기본 지급 아이템 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrantedItemDto {
        private Long userItemId;
        private Long itemId;
        private String name;
        private String itemType;
        private String status;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static GrantedItemDto from(UserItem userItem) {
            return GrantedItemDto.builder()
                    .userItemId(userItem.getId())
                    .itemId(userItem.getItem().getId())
                    .name(userItem.getItem().getName())
                    .itemType(userItem.getItem().getItemType().name())
                    .status(userItem.getStatus().name())
                    .build();
        }
    }

    // 로그인 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginReqDto {

        @NotBlank(message = "이메일은 필수입니다.")
        @Email(message = "올바른 이메일 형식이 아닙니다.")
        private String email;

        @NotBlank(message = "비밀번호는 필수입니다.")
        private String password;
    }

    // 로그인 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginResDto {
        private String accessToken;
        private LoginUserDto user;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static LoginResDto of(String accessToken, User user) {
            return LoginResDto.builder()
                    .accessToken(accessToken)
                    .user(LoginUserDto.from(user))
                    .build();
        }
    }

    // 로그인 응답 내부 사용자 정보 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginUserDto {
        private Long userId;
        private String email;
        private String nickname;
        private String role;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static LoginUserDto from(User user) {
            return LoginUserDto.builder()
                    .userId(user.getId())
                    .email(user.getEmail())
                    .nickname(user.getNickname())
                    .role(user.getRole().name())
                    .build();
        }
    }

    // OAuthLoginReqDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OAuthLoginReqDto {
        private String code;
        private String redirectUri;
    }
}

package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.UserDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

// UserController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ApiResponse<UserDto.MeResDto> getMe(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        UserDto.MeResDto response = userService.getMe(userDetails.getUserId());

        return ApiResponse.success("내 정보 조회 성공", response);
    }

    // update Nickname 수정
    @PatchMapping("/me")
    public ApiResponse<UserDto.UpdateNicknameResDto> updateNickname(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.UpdateNicknameReqDto request
    ) {
        UserDto.UpdateNicknameResDto response = userService.updateNickname(
                userDetails.getUserId(),
                request
        );

        return ApiResponse.success("닉네임이 수정되었습니다.", response);
    }

    // 비밀번호 변경 — 현재 비밀번호 검증 후 기존 JWT 무효화
    @PatchMapping("/me/password")
    public ApiResponse<Void> changePassword(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.ChangePasswordReqDto request
    ) {
        userService.changePassword(userDetails.getUserId(), request);

        return ApiResponse.success("비밀번호가 변경되었습니다. 다시 로그인해주세요.", null);
    }

    // 회원 탈퇴 — soft delete 후 기존 JWT 무효화
    @DeleteMapping("/me")
    public ApiResponse<Void> withdraw(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        userService.withdraw(userDetails.getUserId());

        return ApiResponse.success("회원 탈퇴가 완료되었습니다.", null);
    }

    // 로그아웃 — tokenVersion 증가로 기존 JWT 무효화
    @PostMapping("/me/logout")
    public ApiResponse<Void> logout(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        userService.logout(userDetails.getUserId());

        return ApiResponse.success("로그아웃되었습니다.", null);
    }
}

package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.service.AuthService;
import com.greenlink.greenlink.service.oauth.OAuthLoginService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

// 인증 Controller — 회원가입, 로그인, OAuth
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final OAuthLoginService oauthLoginService;

    // 회원가입 처리 — 사용자 생성 및 기본 데이터 지급
    @PostMapping("/signup")
    public ApiResponse<AuthDto.SignupResDto> signup(
            @Valid @RequestBody AuthDto.SignupReqDto request
    ) {
        AuthDto.SignupResDto response = authService.signup(request);

        return ApiResponse.success("회원가입이 완료되었습니다.", response);
    }

    // 로그인 처리 — 비밀번호 검증 후 JWT 발급
    @PostMapping("/login")
    public ApiResponse<AuthDto.LoginResDto> login(
            @Valid @RequestBody AuthDto.LoginReqDto request
    ) {
        AuthDto.LoginResDto response = authService.login(request);

        return ApiResponse.success("로그인에 성공했습니다.", response);
    }

    // 카카오 OAuth 로그인 처리
    @PostMapping("/oauth/kakao")
    public ApiResponse<AuthDto.LoginResDto> kakaoLogin(
            @RequestBody AuthDto.OAuthLoginReqDto request
    ) {
        AuthDto.LoginResDto response = oauthLoginService.loginWithKakao(request);
        return ApiResponse.success("카카오 로그인 성공", response);
    }

    // Google OAuth 로그인 처리
    @PostMapping("/oauth/google")
    public ApiResponse<AuthDto.LoginResDto> googleLogin(
            @RequestBody AuthDto.OAuthLoginReqDto request
    ) {
        AuthDto.LoginResDto response = oauthLoginService.loginWithGoogle(request);
        return ApiResponse.success("구글 로그인 성공", response);
    }
}

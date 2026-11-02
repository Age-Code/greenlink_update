package com.greenlink.greenlink.service.oauth;

import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// OAuthLoginService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
public class OAuthLoginService {

    private final KakaoOAuthClient kakaoOAuthClient;
    private final GoogleOAuthClient googleOAuthClient;
    private final AuthService authService;

    // 카카오 OAuth 로그인 처리
    @Transactional
    public AuthDto.LoginResDto loginWithKakao(AuthDto.OAuthLoginReqDto request) {
        OAuthUserInfo userInfo = kakaoOAuthClient.getUserInfo(
                request.getCode(),
                request.getRedirectUri()
        );

        return authService.oauthLogin(userInfo);
    }

    // Google OAuth 로그인 처리
    @Transactional
    public AuthDto.LoginResDto loginWithGoogle(AuthDto.OAuthLoginReqDto request) {
        OAuthUserInfo userInfo = googleOAuthClient.getUserInfo(
                request.getCode(),
                request.getRedirectUri()
        );

        return authService.oauthLogin(userInfo);
    }
}
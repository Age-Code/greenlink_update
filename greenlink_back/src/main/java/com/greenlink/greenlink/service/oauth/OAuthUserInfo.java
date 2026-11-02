package com.greenlink.greenlink.service.oauth;

import com.greenlink.greenlink.domain.user.LoginProvider;
import lombok.Builder;
import lombok.Getter;

// OAuthUserInfo — 비즈니스 로직 처리
@Getter
@Builder
public class OAuthUserInfo {
    private LoginProvider provider;
    private String providerId;
    private String email;
    private String nickname;
    private String profileImageUrl;
}

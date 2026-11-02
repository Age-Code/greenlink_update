package com.greenlink.greenlink.service.oauth;

import com.greenlink.greenlink.domain.user.LoginProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;

import java.util.Map;

// KakaoOAuthClient — 비즈니스 로직 처리
@Component
@RequiredArgsConstructor
public class KakaoOAuthClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${oauth.kakao.client-id}")
    private String clientId;

    @Value("${oauth.kakao.client-secret:}")
    private String clientSecret;

    @Value("${oauth.kakao.token-uri}")
    private String tokenUri;

    @Value("${oauth.kakao.user-info-uri}")
    private String userInfoUri;

    public OAuthUserInfo getUserInfo(String code, String redirectUri) {
        String accessToken = requestAccessToken(code, redirectUri);
        return requestUserInfo(accessToken);
    }

    // OAuth access token 요청
    private String requestAccessToken(String code, String redirectUri) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "authorization_code");
        body.add("client_id", clientId);
        body.add("redirect_uri", redirectUri);
        body.add("code", code);

        if (clientSecret != null && !clientSecret.isBlank()) {
            body.add("client_secret", clientSecret);
        }

        HttpEntity<MultiValueMap<String, String>> requestEntity =
                new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    tokenUri,
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            Map<String, Object> responseBody = response.getBody();

            if (responseBody == null || responseBody.get("access_token") == null) {
                throw new IllegalStateException("카카오 access_token 응답이 비어 있습니다.");
            }

            return responseBody.get("access_token").toString();

        } catch (RestClientException e) {
            throw new IllegalStateException("카카오 토큰 요청 실패: " + e.getMessage(), e);
        }
    }

    // OAuth 사용자 정보 요청
    private OAuthUserInfo requestUserInfo(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);

        HttpEntity<Void> requestEntity = new HttpEntity<>(headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    userInfoUri,
                    HttpMethod.GET,
                    requestEntity,
                    Map.class
            );

            Map<String, Object> body = response.getBody();

            if (body == null || body.get("id") == null) {
                throw new IllegalStateException("카카오 사용자 정보 응답이 비어 있습니다.");
            }

            String providerId = body.get("id").toString();

            Map<String, Object> kakaoAccount =
                    (Map<String, Object>) body.get("kakao_account");

            String email = null;
            String nickname = null;
            String profileImageUrl = null;

            if (kakaoAccount != null) {
                Object emailObj = kakaoAccount.get("email");
                if (emailObj != null) {
                    email = emailObj.toString();
                }

                Map<String, Object> profile =
                        (Map<String, Object>) kakaoAccount.get("profile");

                if (profile != null) {
                    Object nicknameObj = profile.get("nickname");
                    Object profileImageObj = profile.get("profile_image_url");

                    if (nicknameObj != null) {
                        nickname = nicknameObj.toString();
                    }

                    if (profileImageObj != null) {
                        profileImageUrl = profileImageObj.toString();
                    }
                }
            }

            if (email == null || email.isBlank()) {
                email = "kakao_" + providerId + "@social.greenlink";
            }

            if (nickname == null || nickname.isBlank()) {
                nickname = "카카오사용자";
            }

            return OAuthUserInfo.builder()
                    .provider(LoginProvider.KAKAO)
                    .providerId(providerId)
                    .email(email)
                    .nickname(nickname)
                    .profileImageUrl(profileImageUrl)
                    .build();

        } catch (RestClientException e) {
            throw new IllegalStateException("카카오 사용자 정보 요청 실패: " + e.getMessage(), e);
        }
    }
}

package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.user.LoginProvider;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.repository.ItemRepository;
import com.greenlink.greenlink.repository.QuestRepository;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserQuestRepository;
import com.greenlink.greenlink.repository.UserRepository;
import com.greenlink.greenlink.security.JwtTokenProvider;
import com.greenlink.greenlink.security.LoginAttemptLimiter;
import com.greenlink.greenlink.service.oauth.OAuthUserInfo;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private ItemRepository itemRepository;
    @Mock
    private UserItemRepository userItemRepository;
    @Mock
    private QuestRepository questRepository;
    @Mock
    private UserQuestRepository userQuestRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtTokenProvider jwtTokenProvider;
    @Mock
    private LoginAttemptLimiter loginAttemptLimiter;

    @InjectMocks
    private AuthService authService;

    @Test
    void loginRejectsOAuthAccountBeforeCheckingPassword() {
        User oauthUser = User.createOAuthUser(
                "social@example.com",
                "encoded-password",
                "social-user",
                LoginProvider.GOOGLE,
                "google-user-id",
                null
        );
        AuthDto.LoginReqDto request = new AuthDto.LoginReqDto(
                "social@example.com",
                "SOCIAL_LOGIN_GOOGLE_google-user-id"
        );

        given(userRepository.findByEmailAndDeletedFalse(request.getEmail()))
                .willReturn(Optional.of(oauthUser));

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("이메일 또는 비밀번호가 올바르지 않습니다.");

        verify(passwordEncoder, never()).matches(anyString(), anyString());
        verify(jwtTokenProvider, never()).createAccessToken(any(), anyString(), anyString(), anyInt());
    }

    @Test
    void loginAllowsLocalAccountWithMatchingPassword() {
        User localUser = User.createUser(
                "local@example.com",
                "encoded-password",
                "local-user"
        );
        AuthDto.LoginReqDto request = new AuthDto.LoginReqDto(
                "local@example.com",
                "plain-password"
        );

        given(userRepository.findByEmailAndDeletedFalse(request.getEmail()))
                .willReturn(Optional.of(localUser));
        given(passwordEncoder.matches(request.getPassword(), localUser.getPassword()))
                .willReturn(true);
        given(jwtTokenProvider.createAccessToken(
                localUser.getId(),
                localUser.getEmail(),
                localUser.getRole().name(),
                localUser.getTokenVersion()
        )).willReturn("access-token");

        AuthDto.LoginResDto response = authService.login(request);

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getUser().getEmail()).isEqualTo(localUser.getEmail());
    }

    @Test
    void oauthLoginCreatesAnUnpredictableInternalPassword() {
        OAuthUserInfo userInfo = OAuthUserInfo.builder()
                .provider(LoginProvider.GOOGLE)
                .providerId("google-user-id")
                .email("social@example.com")
                .nickname("social-user")
                .build();
        Item basilSeed = Item.createPot("바질 씨앗", null, null);
        Item basicPot = Item.createPot("기본 화분", null, null);

        given(userRepository.findByProviderAndProviderIdAndDeletedFalse(
                userInfo.getProvider(),
                userInfo.getProviderId()
        )).willReturn(Optional.empty());
        given(passwordEncoder.encode(anyString())).willReturn("encoded-password");
        given(userRepository.save(any(User.class)))
                .willAnswer(invocation -> invocation.getArgument(0));
        given(itemRepository.findByNameAndDeletedFalse("바질 씨앗"))
                .willReturn(Optional.of(basilSeed));
        given(itemRepository.findByNameAndDeletedFalse("기본 화분"))
                .willReturn(Optional.of(basicPot));
        given(userItemRepository.existsByUserAndItemAndDeletedFalse(any(), any()))
                .willReturn(true);
        given(questRepository.findAllByQuestTypeAndActiveTrueAndDeletedFalse(any()))
                .willReturn(List.of());

        authService.oauthLogin(userInfo);
        authService.oauthLogin(userInfo);

        ArgumentCaptor<String> passwordCaptor = ArgumentCaptor.forClass(String.class);
        verify(passwordEncoder, times(2)).encode(passwordCaptor.capture());

        List<String> generatedPasswords = passwordCaptor.getAllValues();
        assertThat(generatedPasswords)
                .hasSize(2)
                .doesNotHaveDuplicates()
                .allMatch(password -> !password.contains(userInfo.getProviderId()))
                .allMatch(password -> !password.contains(userInfo.getProvider().name()));
    }
}

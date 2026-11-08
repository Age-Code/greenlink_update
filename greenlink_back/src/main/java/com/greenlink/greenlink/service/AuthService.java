package com.greenlink.greenlink.service;

import com.greenlink.greenlink.config.DefaultDataInitializer;
import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.UserQuest;
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
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

// AuthService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private static final String DEFAULT_SEED_NAME = DefaultDataInitializer.DEFAULT_SEED_NAME;
    private static final String DEFAULT_POT_NAME = DefaultDataInitializer.DEFAULT_POT_NAME;

    private final UserRepository userRepository;
    private final ItemRepository itemRepository;
    private final UserItemRepository userItemRepository;
    private final QuestRepository questRepository;
    private final UserQuestRepository userQuestRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final LoginAttemptLimiter loginAttemptLimiter;

    // 회원가입 처리 — 사용자 생성 및 기본 데이터 지급
    @Transactional
    public AuthDto.SignupResDto signup(AuthDto.SignupReqDto request) {
        validateDuplicateEmail(request.getEmail());

        String encodedPassword = passwordEncoder.encode(request.getPassword());

        User user = User.createUser(
                request.getEmail(),
                encodedPassword,
                request.getNickname()
        );

        User savedUser = userRepository.save(user);

        List<UserItem> grantedItems = grantDefaultItemsIfMissing(savedUser);

        createAchievementUserQuestsIfMissing(savedUser);

        return AuthDto.SignupResDto.of(savedUser, grantedItems);
    }

    // 로그인 처리 — 비밀번호 검증 후 JWT 발급
    public AuthDto.LoginResDto login(AuthDto.LoginReqDto request) {
        // 같은 이메일로 연속 실패하면 잠시 막는다. — 앱 로그인과 관리자 웹 로그인 모두 이 경로를 쓴다.
        loginAttemptLimiter.checkAllowed(request.getEmail());

        User user = userRepository.findByEmailAndDeletedFalse(request.getEmail()).orElse(null);

        if (user == null
                || user.getProvider() != LoginProvider.LOCAL
                || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            loginAttemptLimiter.recordFailure(request.getEmail());
            throw new IllegalArgumentException("이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        loginAttemptLimiter.recordSuccess(request.getEmail());

        String accessToken = jwtTokenProvider.createAccessToken(
                user.getId(),
                user.getEmail(),
                user.getRole().name(),
                user.getTokenVersion()
        );

        return AuthDto.LoginResDto.of(accessToken, user);
    }

    // OAuth 로그인 처리
    @Transactional
    public AuthDto.LoginResDto oauthLogin(OAuthUserInfo userInfo) {
        User user = userRepository
                .findByProviderAndProviderIdAndDeletedFalse(
                        userInfo.getProvider(),
                        userInfo.getProviderId()
                )
                .orElseGet(() -> createOAuthUserFromOAuthInfo(userInfo));

                // 중요: — 기존에 OAuth로 가입되어 있었지만 기본 아이템을 못 받은 유저를 보정한다.

        grantDefaultItemsIfMissing(user);

        createAchievementUserQuestsIfMissing(user);

        String accessToken = jwtTokenProvider.createAccessToken(
                user.getId(),
                user.getEmail(),
                user.getRole().name(),
                user.getTokenVersion()
        );

        return AuthDto.LoginResDto.of(accessToken, user);
    }

    // create OAuth User From OAuth Info 생성
    private User createOAuthUserFromOAuthInfo(OAuthUserInfo userInfo) {
        // 같은 이메일의 다른 계정이 있으면 unique 위반(500) 대신 409로 안내한다. — 자동 계정 연결은 하지 않는다.
        if (userInfo.getEmail() != null && userRepository.existsByEmail(userInfo.getEmail())) {
            throw new IllegalStateException("이미 같은 이메일로 가입된 계정이 있습니다. 기존 로그인 방식으로 로그인해주세요.");
        }

        String socialPassword = passwordEncoder.encode(UUID.randomUUID().toString());

        User user = User.createOAuthUser(
                userInfo.getEmail(),
                socialPassword,
                userInfo.getNickname(),
                userInfo.getProvider(),
                userInfo.getProviderId(),
                userInfo.getProfileImageUrl()
        );

        return userRepository.save(user);
    }

    // validate Duplicate Email 검증
    private void validateDuplicateEmail(String email) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }
    }

    // grant Default Items If Missing 지급
    private List<UserItem> grantDefaultItemsIfMissing(User user) {
        Item basilSeed = itemRepository.findByNameAndDeletedFalse(DEFAULT_SEED_NAME)
                .orElseThrow(() -> new IllegalStateException("기본 지급 아이템인 바질 씨앗이 등록되어 있지 않습니다."));

        Item basicPot = itemRepository.findByNameAndDeletedFalse(DEFAULT_POT_NAME)
                .orElseThrow(() -> new IllegalStateException("기본 지급 아이템인 기본 화분이 등록되어 있지 않습니다."));

        List<UserItem> grantedItems = new ArrayList<>();

        boolean hasBasilSeed = userItemRepository.existsByUserAndItemAndDeletedFalse(
                user,
                basilSeed
        );

        if (!hasBasilSeed) {
            UserItem basilSeedItem = userItemRepository.save(
                    UserItem.createOwned(user, basilSeed)
            );
            grantedItems.add(basilSeedItem);
        }

        boolean hasBasicPot = userItemRepository.existsByUserAndItemAndDeletedFalse(
                user,
                basicPot
        );

        if (!hasBasicPot) {
            UserItem basicPotItem = userItemRepository.save(
                    UserItem.createOwned(user, basicPot)
            );
            grantedItems.add(basicPotItem);
        }

        return grantedItems;
    }

    // create Achievement User Quests If Missing 생성
    private void createAchievementUserQuestsIfMissing(User user) {
        List<Quest> achievementQuests =
                questRepository.findAllByQuestTypeAndActiveTrueAndDeletedFalse(
                        QuestType.ACHIEVEMENT
                );

        LocalDateTime now = LocalDateTime.now();

        for (Quest quest : achievementQuests) {
            boolean alreadyExists = userQuestRepository.existsByUserAndQuestAndDeletedFalse(
                    user,
                    quest
            );

            if (alreadyExists) {
                continue;
            }

            UserQuest userQuest = UserQuest.create(user, quest, now);
            userQuestRepository.save(userQuest);
        }
    }
}

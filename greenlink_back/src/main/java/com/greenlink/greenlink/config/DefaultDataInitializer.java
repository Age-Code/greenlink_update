package com.greenlink.greenlink.config;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.domain.user.UserRole;
import com.greenlink.greenlink.repository.ItemRepository;
import com.greenlink.greenlink.repository.PlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

// 기본 데이터 부트스트랩 — 빈 DB에서도 회원가입·관리자 로그인이 가능하도록 최소 데이터를 보장한다.
// 이미 있는 데이터는 수정하지 않으며, 여러 번 실행되어도 결과가 같다.
@Slf4j
@Component
public class DefaultDataInitializer implements ApplicationRunner {

    // 회원가입 시 지급되는 기본 아이템 — AuthService가 이 이름으로 조회한다.
    public static final String DEFAULT_SEED_NAME = "바질 씨앗";
    public static final String DEFAULT_POT_NAME = "기본 화분";

    private static final String DEFAULT_PLANT_NAME = "바질";
    private static final String DEFAULT_PLANT_CATEGORY = "HERB";
    private static final int DEFAULT_PLANT_GROWTH_DAYS = 30;

    private static final int MIN_ADMIN_PASSWORD_LENGTH = 12;
    private static final String DEFAULT_ADMIN_NICKNAME = "admin";

    private final PlantRepository plantRepository;
    private final ItemRepository itemRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private final boolean seedDefaultData;
    private final String adminEmail;
    private final String adminPassword;

    public DefaultDataInitializer(
            PlantRepository plantRepository,
            ItemRepository itemRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            @Value("${greenlink.bootstrap.seed-default-data:true}") boolean seedDefaultData,
            @Value("${greenlink.bootstrap.admin-email:}") String adminEmail,
            @Value("${greenlink.bootstrap.admin-password:}") String adminPassword
    ) {
        this.plantRepository = plantRepository;
        this.itemRepository = itemRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.seedDefaultData = seedDefaultData;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (seedDefaultData) {
            seedDefaultItems();
        }

        bootstrapAdminIfNeeded();
    }

    // 기본 식물(바질)과 기본 지급 아이템(바질 씨앗, 기본 화분) 생성 — 없을 때만
    void seedDefaultItems() {
        Plant basil = plantRepository.findByNameAndDeletedFalse(DEFAULT_PLANT_NAME)
                .orElseGet(() -> {
                    log.info("[BOOTSTRAP] 기본 식물 생성: {}", DEFAULT_PLANT_NAME);
                    return plantRepository.save(Plant.create(
                            DEFAULT_PLANT_NAME,
                            DEFAULT_PLANT_CATEGORY,
                            "GreenLink 기본 지급 식물",
                            null,
                            DEFAULT_PLANT_GROWTH_DAYS
                    ));
                });

        if (!itemRepository.existsByNameAndDeletedFalse(DEFAULT_SEED_NAME)) {
            log.info("[BOOTSTRAP] 기본 아이템 생성: {}", DEFAULT_SEED_NAME);
            itemRepository.save(Item.createSeed(DEFAULT_SEED_NAME, "회원가입 기본 지급 씨앗", null, basil));
        }

        if (!itemRepository.existsByNameAndDeletedFalse(DEFAULT_POT_NAME)) {
            log.info("[BOOTSTRAP] 기본 아이템 생성: {}", DEFAULT_POT_NAME);
            itemRepository.save(Item.createPot(DEFAULT_POT_NAME, "회원가입 기본 지급 화분", null));
        }
    }

    // 최초 ADMIN 생성 — ADMIN이 한 명도 없고 이메일·비밀번호가 설정된 경우에만
    void bootstrapAdminIfNeeded() {
        if (userRepository.existsByRoleAndDeletedFalse(UserRole.ADMIN)) {
            return;
        }

        if (adminEmail.isBlank() || adminPassword.isBlank()) {
            log.warn("[BOOTSTRAP] ADMIN 계정이 없습니다. GREENLINK_BOOTSTRAP_ADMIN_EMAIL/PASSWORD로 최초 관리자를 만들 수 있습니다.");
            return;
        }

        if (adminPassword.length() < MIN_ADMIN_PASSWORD_LENGTH) {
            log.error("[BOOTSTRAP] 최초 관리자 비밀번호는 {}자 이상이어야 합니다. 관리자를 생성하지 않았습니다.",
                    MIN_ADMIN_PASSWORD_LENGTH);
            return;
        }

        // 기존 일반 계정을 자동 승격하지 않는다. — 이메일만 알면 권한을 얻는 경로를 만들지 않기 위해
        if (userRepository.existsByEmail(adminEmail)) {
            log.error("[BOOTSTRAP] {} 이메일을 이미 다른 계정이 사용 중입니다. 관리자를 생성하지 않았습니다.", adminEmail);
            return;
        }

        userRepository.save(User.createAdmin(
                adminEmail,
                passwordEncoder.encode(adminPassword),
                DEFAULT_ADMIN_NICKNAME
        ));

        log.info("[BOOTSTRAP] 최초 관리자 계정을 생성했습니다: {}. 로그인 후 부트스트랩 환경변수를 제거하세요.", adminEmail);
    }
}

package com.greenlink.greenlink.config;

import com.greenlink.greenlink.domain.user.UserRole;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.repository.ItemRepository;
import com.greenlink.greenlink.repository.UserRepository;
import com.greenlink.greenlink.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

// 빈 DB(H2 create-drop)에서 부트스트랩만으로 가입과 관리자 로그인이 가능한지 확인한다.
@SpringBootTest(properties = {
        "greenlink.bootstrap.admin-email=bootstrap-admin@example.com",
        "greenlink.bootstrap.admin-password=bootstrap-admin-password"
})
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class DefaultDataInitializerTest {

    @Autowired
    private ItemRepository itemRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private AuthService authService;
    @Autowired
    private DefaultDataInitializer defaultDataInitializer;

    @Test
    void emptyDatabaseGetsDefaultItemsAndFirstAdmin() {
        assertThat(itemRepository.existsByNameAndDeletedFalse(DefaultDataInitializer.DEFAULT_SEED_NAME)).isTrue();
        assertThat(itemRepository.existsByNameAndDeletedFalse(DefaultDataInitializer.DEFAULT_POT_NAME)).isTrue();

        AuthDto.LoginResDto admin = authService.login(
                new AuthDto.LoginReqDto("bootstrap-admin@example.com", "bootstrap-admin-password")
        );
        assertThat(admin.getUser().getRole()).isEqualTo(UserRole.ADMIN.name());
    }

    @Test
    void signupGrantsDefaultItemsOnFreshDatabase() {
        AuthDto.SignupResDto response = authService.signup(
                new AuthDto.SignupReqDto("new-user@example.com", "password", "new-user")
        );

        assertThat(response.getGrantedItems()).hasSize(2);
    }

    @Test
    void rerunningBootstrapDoesNotDuplicateData() {
        long itemCount = itemRepository.count();
        long userCount = userRepository.count();

        defaultDataInitializer.run(null);

        assertThat(itemRepository.count()).isEqualTo(itemCount);
        assertThat(userRepository.count()).isEqualTo(userCount);
    }
}

package com.greenlink.greenlink.domain.user;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UserTest {

    @Test
    void withdrawReleasesEmailForReSignup() {
        User user = User.createUser("user@example.com", "encoded-password", "user");

        user.withdraw();

        assertThat(user.isDeleted()).isTrue();
        assertThat(user.getEmail()).isNotEqualTo("user@example.com");
        assertThat(user.getEmail()).endsWith("@withdrawn.invalid");
        assertThat(user.getEmail().length()).isLessThanOrEqualTo(100);
        assertThat(user.getProviderId()).isNull();
    }
}

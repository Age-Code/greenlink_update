package com.greenlink.greenlink.security;

import com.greenlink.greenlink.common.TooManyRequestsException;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LoginAttemptLimiterTest {

    private final AtomicReference<Instant> now = new AtomicReference<>(Instant.parse("2026-11-07T00:00:00Z"));
    private final LoginAttemptLimiter limiter = new LoginAttemptLimiter(new Clock() {
        @Override
        public java.time.ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now.get();
        }
    });

    @Test
    void locksAfterFiveFailuresAndUnlocksLater() {
        for (int i = 0; i < LoginAttemptLimiter.MAX_FAILURES - 1; i++) {
            limiter.recordFailure("User@Example.com");
        }
        assertThatCode(() -> limiter.checkAllowed("user@example.com")).doesNotThrowAnyException();

        limiter.recordFailure("user@example.com");
        assertThatThrownBy(() -> limiter.checkAllowed("USER@example.com"))
                .isInstanceOf(TooManyRequestsException.class);

        now.set(now.get().plus(LoginAttemptLimiter.LOCK_DURATION).plusSeconds(1));
        assertThatCode(() -> limiter.checkAllowed("user@example.com")).doesNotThrowAnyException();
    }

    @Test
    void successClearsFailuresAndOldFailuresExpire() {
        for (int i = 0; i < LoginAttemptLimiter.MAX_FAILURES - 1; i++) {
            limiter.recordFailure("a@example.com");
        }
        limiter.recordSuccess("a@example.com");
        limiter.recordFailure("a@example.com");
        assertThatCode(() -> limiter.checkAllowed("a@example.com")).doesNotThrowAnyException();

        for (int i = 0; i < LoginAttemptLimiter.MAX_FAILURES - 1; i++) {
            limiter.recordFailure("b@example.com");
        }
        now.set(now.get().plus(Duration.ofMinutes(11)));
        limiter.recordFailure("b@example.com");
        assertThatCode(() -> limiter.checkAllowed("b@example.com")).doesNotThrowAnyException();
    }
}

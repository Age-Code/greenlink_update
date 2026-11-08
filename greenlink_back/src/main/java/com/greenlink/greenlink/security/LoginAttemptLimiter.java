package com.greenlink.greenlink.security;

import com.greenlink.greenlink.common.TooManyRequestsException;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

// 로그인 무차별 대입 방지 — 같은 이메일로 10분 안에 5번 틀리면 10분 동안 로그인을 막는다.
// 서버 1대(Docker 컨테이너 1개) 운영 기준이라 메모리에 둔다. 재시작하면 기록은 초기화된다.
@Component
public class LoginAttemptLimiter {

    static final int MAX_FAILURES = 5;
    static final Duration FAILURE_WINDOW = Duration.ofMinutes(10);
    static final Duration LOCK_DURATION = Duration.ofMinutes(10);
    private static final int CLEANUP_THRESHOLD = 10_000;

    private final Map<String, Attempt> attempts = new ConcurrentHashMap<>();
    private final Clock clock;

    public LoginAttemptLimiter() {
        this(Clock.systemDefaultZone());
    }

    LoginAttemptLimiter(Clock clock) {
        this.clock = clock;
    }

    // 잠겨 있으면 429
    public void checkAllowed(String email) {
        Attempt attempt = attempts.get(key(email));

        if (attempt != null && attempt.lockedUntil != null && clock.instant().isBefore(attempt.lockedUntil)) {
            long minutes = Math.max(1, Duration.between(clock.instant(), attempt.lockedUntil).toMinutes());
            throw new TooManyRequestsException(
                    "로그인 시도가 너무 많습니다. " + minutes + "분 뒤에 다시 시도해주세요."
            );
        }
    }

    public void recordFailure(String email) {
        Instant now = clock.instant();

        attempts.compute(key(email), (k, previous) -> {
            Attempt attempt = previous == null || now.isAfter(previous.windowStart.plus(FAILURE_WINDOW))
                    ? new Attempt(now)
                    : previous;

            attempt.failures++;

            if (attempt.failures >= MAX_FAILURES) {
                attempt.lockedUntil = now.plus(LOCK_DURATION);
                attempt.failures = 0;
                attempt.windowStart = now;
            }

            return attempt;
        });

        if (attempts.size() > CLEANUP_THRESHOLD) {
            removeExpired(now);
        }
    }

    public void recordSuccess(String email) {
        attempts.remove(key(email));
    }

    private void removeExpired(Instant now) {
        attempts.entrySet().removeIf(entry -> {
            Attempt attempt = entry.getValue();
            boolean lockExpired = attempt.lockedUntil == null || now.isAfter(attempt.lockedUntil);
            boolean windowExpired = now.isAfter(attempt.windowStart.plus(FAILURE_WINDOW));
            return lockExpired && windowExpired;
        });
    }

    private String key(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private static final class Attempt {
        private Instant windowStart;
        private int failures;
        private Instant lockedUntil;

        private Attempt(Instant windowStart) {
            this.windowStart = windowStart;
        }
    }
}

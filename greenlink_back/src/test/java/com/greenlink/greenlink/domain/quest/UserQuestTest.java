package com.greenlink.greenlink.domain.quest;

import com.greenlink.greenlink.domain.user.User;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class UserQuestTest {

    @Test
    void monthlyQuestExpiresOneCalendarMonthAfterItStarts() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Quest quest = Quest.create(
                "monthly quest",
                null,
                QuestType.MONTHLY,
                TargetType.ATTEND,
                1,
                null,
                1,
                ResetCycle.MONTHLY
        );
        LocalDateTime startedAt = LocalDateTime.of(2024, 1, 31, 10, 30);
        UserQuest userQuest = UserQuest.create(user, quest, startedAt);

        assertThat(userQuest.getExpiredAt())
                .isEqualTo(LocalDateTime.of(2024, 2, 29, 10, 30));
    }

    @Test
    void achievementNeverExpiresEvenWithResetCycle() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Quest quest = Quest.create(
                "achievement",
                null,
                QuestType.ACHIEVEMENT,
                TargetType.ATTEND,
                10,
                null,
                1,
                ResetCycle.DAILY
        );
        UserQuest userQuest = UserQuest.create(user, quest, LocalDateTime.of(2024, 1, 1, 0, 0));

        assertThat(userQuest.getExpiredAt()).isNull();
        assertThat(userQuest.isExpiredBy(LocalDateTime.of(2030, 1, 1, 0, 0))).isFalse();
    }
}

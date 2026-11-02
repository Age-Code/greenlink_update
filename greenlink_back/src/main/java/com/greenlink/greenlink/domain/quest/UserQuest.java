package com.greenlink.greenlink.domain.quest;

import com.greenlink.greenlink.common.BaseEntity;
import com.greenlink.greenlink.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Entity
@Table(
        name = "user_quest",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_user_quest_user_quest_started",
                        columnNames = {"user_id", "quest_id", "started_at"}
                )
        }
)
// UserQuest — 도메인 모델
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserQuest extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 퀘스트를 진행하는 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 어떤 퀘스트인지
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quest_id", nullable = false)
    private Quest quest;

    // 현재 진행도
    @Column(name = "progress_value", nullable = false)
    private Integer progressValue;

    // IN_PROGRESS, ACHIEVABLE, COMPLETED, EXPIRED
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private UserQuestStatus status;

    // 실제 퀘스트 시작 시간
    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    // 퀘스트 완료 시간
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    // 보상 수령 시간
    @Column(name = "reward_received_at")
    private LocalDateTime rewardReceivedAt;

    // UserQuest 생성
    private UserQuest(User user, Quest quest, LocalDateTime startedAt) {
        this.user = user;
        this.quest = quest;
        this.progressValue = 0;
        this.status = UserQuestStatus.IN_PROGRESS;
        this.startedAt = startedAt;
    }

    // create 생성
    public static UserQuest create(User user, Quest quest, LocalDateTime startedAt) {
        return new UserQuest(user, quest, startedAt);
    }

    public boolean isOwner(User user) {
        return this.user.getId().equals(user.getId());
    }

    public boolean isAchievable() {
        return this.status == UserQuestStatus.ACHIEVABLE;
    }

    public boolean isCompleted() {
        return this.status == UserQuestStatus.COMPLETED;
    }

    public boolean isExpired() {
        return this.status == UserQuestStatus.EXPIRED;
    }

    // 퀘스트 진행 증가 — TargetType 활성 퀘스트 progress 반영
    public void increaseProgress(int amount) {
        if (amount <= 0) {
            return;
        }

        if (this.status != UserQuestStatus.IN_PROGRESS) {
            return;
        }

        this.progressValue += amount;

        if (this.progressValue >= this.quest.getTargetValue()) {
            this.progressValue = this.quest.getTargetValue();
            this.status = UserQuestStatus.ACHIEVABLE;
            this.completedAt = LocalDateTime.now();
        }
    }

    // complete Reward 완료 처리
    public void completeReward() {
        if (this.status != UserQuestStatus.ACHIEVABLE) {
            throw new IllegalStateException("보상을 수령할 수 있는 상태가 아닙니다.");
        }

        this.status = UserQuestStatus.COMPLETED;
        this.rewardReceivedAt = LocalDateTime.now();
    }

    // expire 처리
    public void expire() {
        if (this.status == UserQuestStatus.COMPLETED) {
            return;
        }

        this.status = UserQuestStatus.EXPIRED;
    }

    public LocalDateTime getExpiredAt() {
        // 업적은 resetCycle 설정과 무관하게 만료되지 않는다.
        if (this.quest.getQuestType() == QuestType.ACHIEVEMENT) {
            return null;
        }

        return switch (this.quest.getResetCycle()) {
            case DAILY -> this.startedAt.plusDays(1);
            case WEEKLY -> this.startedAt.plusDays(7);
            case MONTHLY -> this.startedAt.plusMonths(1);
            case NONE -> null;
        };
    }

    public boolean isExpiredBy(LocalDateTime now) {
        LocalDateTime expiredAt = getExpiredAt();

        if (expiredAt == null) {
            return false;
        }

        return !now.isBefore(expiredAt);
    }
}

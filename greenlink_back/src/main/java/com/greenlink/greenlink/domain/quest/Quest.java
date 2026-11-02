package com.greenlink.greenlink.domain.quest;

import com.greenlink.greenlink.common.BaseEntity;
import com.greenlink.greenlink.domain.item.Item;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

// Quest — 도메인 모델
@Getter
@Entity
@Table(name = "quest")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Quest extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 퀘스트 제목
    @Column(nullable = false, length = 100)
    private String title;

    // 퀘스트 설명
    @Column(columnDefinition = "TEXT")
    private String description;

    // DAILY, WEEKLY, MONTHLY, ACHIEVEMENT
    @Enumerated(EnumType.STRING)
    @Column(name = "quest_type", nullable = false, length = 30)
    private QuestType questType;

    // ATTEND, WATERING, GROW_PLANT, HARVEST
    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false, length = 50)
    private TargetType targetType;

    // 목표 수치
    @Column(name = "target_value", nullable = false)
    private Integer targetValue;

    // 보상 아이템
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reward_item_id")
    private Item rewardItem;

    // 보상 수량
    @Column(name = "reward_quantity", nullable = false)
    private Integer rewardQuantity;

    // DAILY, WEEKLY, MONTHLY, NONE
    @Enumerated(EnumType.STRING)
    @Column(name = "reset_cycle", nullable = false, length = 30)
    private ResetCycle resetCycle;

    // 활성화 여부
    @Column(nullable = false)
    private Boolean active;

    // Quest 생성
    private Quest(
            String title,
            String description,
            QuestType questType,
            TargetType targetType,
            Integer targetValue,
            Item rewardItem,
            Integer rewardQuantity,
            ResetCycle resetCycle,
            Boolean active
    ) {
        this.title = title;
        this.description = description;
        this.questType = questType;
        this.targetType = targetType;
        this.targetValue = targetValue;
        this.rewardItem = rewardItem;
        this.rewardQuantity = rewardQuantity;
        this.resetCycle = resetCycle;
        this.active = active;
    }

    // create 생성
    public static Quest create(
            String title,
            String description,
            QuestType questType,
            TargetType targetType,
            Integer targetValue,
            Item rewardItem,
            Integer rewardQuantity,
            ResetCycle resetCycle
    ) {
        return new Quest(
                title,
                description,
                questType,
                targetType,
                targetValue,
                rewardItem,
                rewardQuantity,
                resetCycle,
                true
        );
    }

    // update 수정
    public void update(
            String title,
            String description,
            QuestType questType,
            TargetType targetType,
            Integer targetValue,
            Item rewardItem,
            Integer rewardQuantity,
            ResetCycle resetCycle,
            Boolean active
    ) {
        this.title = title;
        this.description = description;
        this.questType = questType;
        this.targetType = targetType;
        this.targetValue = targetValue;
        this.rewardItem = rewardItem;
        this.rewardQuantity = rewardQuantity;
        this.resetCycle = resetCycle;
        this.active = active;
    }

    public boolean isAchievement() {
        return this.questType == QuestType.ACHIEVEMENT;
    }

    public boolean isDaily() {
        return this.questType == QuestType.DAILY;
    }

    public boolean isWeekly() {
        return this.questType == QuestType.WEEKLY;
    }

    public boolean isMonthly() {
        return this.questType == QuestType.MONTHLY;
    }

    public boolean isActive() {
        return Boolean.TRUE.equals(this.active) && !this.isDeleted();
    }
}

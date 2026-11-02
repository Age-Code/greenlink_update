package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.ResetCycle;
import com.greenlink.greenlink.domain.quest.UserQuest;
import com.greenlink.greenlink.domain.quest.UserQuestStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.QuestDto;
import com.greenlink.greenlink.repository.QuestRepository;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserQuestRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;

// UserQuestService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserQuestService {

    private final UserRepository userRepository;
    private final QuestRepository questRepository;
    private final UserQuestRepository userQuestRepository;
    private final UserItemRepository userItemRepository;

    @Transactional
    public List<QuestDto.UserQuestListResDto> getUserQuests(
            Long userId,
            QuestType questType,
            UserQuestStatus status
    ) {
        User user = findActiveUser(userId);

                // 현재 날짜 기준으로 오늘/이번 주/이번 달에 해당하는 user_quest가 없으면 생성한다. — DAILY, WEEKLY, MONTHLY는 현재 기간 기준으로 생성되고,

        createCurrentUserQuestsIfNotExists(user);

        LocalDate today = LocalDate.now();

        List<UserQuest> userQuests = userQuestRepository.findAllByUserAndDeletedFalse(user);

                // 기존에 생성되어 있던 과거 기간 퀘스트는 상태를 EXPIRED로 갱신할 수 있다. — 단, 목록 응답에서는 아래 isVisibleCurrentQuest()로 현재 기간 퀘스트만 보여준다.

        userQuests.forEach(this::expireIfNeeded);

        return userQuests.stream()
                .filter(userQuest -> isVisibleCurrentQuest(userQuest, today))
                .filter(userQuest -> questType == null || userQuest.getQuest().getQuestType() == questType)
                .filter(userQuest -> status == null || userQuest.getStatus() == status)
                .map(QuestDto.UserQuestListResDto::from)
                .toList();
    }

    @Transactional
    public QuestDto.UserQuestDetailResDto getUserQuest(Long userId, Long userQuestId) {
        User user = findActiveUser(userId);

        UserQuest userQuest = userQuestRepository.findByIdAndUserAndDeletedFalse(userQuestId, user)
                .orElseThrow(() -> new IllegalArgumentException("내 퀘스트를 찾을 수 없습니다."));

        expireIfNeeded(userQuest);

        // 과거 기간 퀘스트 상세 조회는 허용한다.
        return QuestDto.UserQuestDetailResDto.from(userQuest);
    }

    // 퀘스트 보상 수령 처리
    @Transactional
    public QuestDto.UserQuestRewardResDto receiveReward(Long userId, Long userQuestId) {
        User user = findActiveUser(userId);

        UserQuest userQuest = userQuestRepository.findWithLockByIdAndUserAndDeletedFalse(userQuestId, user)
                .orElseThrow(() -> new IllegalArgumentException("내 퀘스트를 찾을 수 없습니다."));

        expireIfNeeded(userQuest);

        // 보상 수령은 현재 기간 퀘스트 또는 업적 퀘스트만 허용한다.
        if (!isVisibleCurrentQuest(userQuest, LocalDate.now())) {
            throw new IllegalStateException("현재 기간의 퀘스트만 보상을 수령할 수 있습니다.");
        }

        if (userQuest.getStatus() != UserQuestStatus.ACHIEVABLE) {
            throw new IllegalStateException("아직 보상을 수령할 수 없는 퀘스트입니다.");
        }

        Quest quest = userQuest.getQuest();
        Item rewardItem = quest.getRewardItem();
        Integer rewardQuantity = quest.getRewardQuantity();

        if (rewardItem == null || rewardQuantity == null || rewardQuantity <= 0) {
            throw new IllegalStateException("지급할 보상 아이템이 없습니다.");
        }

        List<UserItem> createdUserItems = new ArrayList<>();

        for (int i = 0; i < rewardQuantity; i++) {
            UserItem userItem = UserItem.createOwned(user, rewardItem);
            createdUserItems.add(userItemRepository.save(userItem));
        }

        userQuest.completeReward();

        return QuestDto.UserQuestRewardResDto.of(
                userQuest,
                rewardItem,
                rewardQuantity,
                createdUserItems
        );
    }

    // create Current User Quests If Not Exists 생성
    private void createCurrentUserQuestsIfNotExists(User user) {
        List<Quest> activeQuests = questRepository.findAllByActiveTrueAndDeletedFalse();
        LocalDate today = LocalDate.now();

        for (Quest quest : activeQuests) {
            createCurrentUserQuestIfNotExists(user, quest, today);
        }
    }

    // create Current User Quest If Not Exists 생성
    private void createCurrentUserQuestIfNotExists(User user, Quest quest, LocalDate today) {
        if (quest.getQuestType() == QuestType.ACHIEVEMENT || quest.getResetCycle() == ResetCycle.NONE) {
            userQuestRepository.findFirstByUserAndQuestAndDeletedFalse(user, quest)
                    .orElseGet(() -> userQuestRepository.save(
                            UserQuest.create(user, quest, LocalDateTime.now())
                    ));
            return;
        }

        LocalDateTime periodStart = getPeriodStart(quest.getResetCycle(), today);

        userQuestRepository.findByUserAndQuestAndStartedAtAndDeletedFalse(user, quest, periodStart)
                .orElseGet(() -> userQuestRepository.save(
                        UserQuest.create(user, quest, periodStart)
                ));
    }

    private boolean isVisibleCurrentQuest(UserQuest userQuest, LocalDate today) {
        Quest quest = userQuest.getQuest();

                // 업적 퀘스트는 기간형 퀘스트가 아니므로 계속 보여준다.

        if (quest.getQuestType() == QuestType.ACHIEVEMENT) {
            return true;
        }

                // resetCycle이 NONE인 퀘스트도 기간 제한이 없으므로 계속 보여준다.

        if (quest.getResetCycle() == ResetCycle.NONE) {
            return true;
        }

        LocalDateTime currentPeriodStart = getPeriodStart(quest.getResetCycle(), today);

        return userQuest.getStartedAt() != null
                && userQuest.getStartedAt().isEqual(currentPeriodStart);
    }

    private LocalDateTime getPeriodStart(ResetCycle resetCycle, LocalDate today) {
        return switch (resetCycle) {
            case DAILY -> today.atStartOfDay();

            case WEEKLY -> today
                    .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                    .atStartOfDay();

            case MONTHLY -> today
                    .withDayOfMonth(1)
                    .atStartOfDay();

            case NONE -> today.atStartOfDay();
        };
    }

    // 기간 만료 퀘스트 처리
    private void expireIfNeeded(UserQuest userQuest) {
        if (userQuest.getStatus() != UserQuestStatus.IN_PROGRESS) {
            return;
        }

        if (userQuest.isExpiredBy(LocalDateTime.now())) {
            userQuest.expire();
        }
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

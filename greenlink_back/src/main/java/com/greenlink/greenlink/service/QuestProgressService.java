package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.ResetCycle;
import com.greenlink.greenlink.domain.quest.TargetType;
import com.greenlink.greenlink.domain.quest.UserQuest;
import com.greenlink.greenlink.domain.quest.UserQuestStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.repository.QuestRepository;
import com.greenlink.greenlink.repository.UserQuestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

// 퀘스트 진행 서비스 — TargetType별 진행도 증가
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class QuestProgressService {

    private final QuestRepository questRepository;
    private final UserQuestRepository userQuestRepository;

    // 퀘스트 진행 증가 — TargetType 활성 퀘스트 progress 반영
    @Transactional
    public void increaseProgress(User user, TargetType targetType, int amount) {
        List<Quest> quests = questRepository.findAllByTargetTypeAndActiveTrueAndDeletedFalse(targetType);

        LocalDate today = LocalDate.now();

        for (Quest quest : quests) {
            UserQuest userQuest = getOrCreateCurrentUserQuest(user, quest, today);

            expireIfNeeded(userQuest);

            if (userQuest.getStatus() == UserQuestStatus.IN_PROGRESS) {
                userQuest.increaseProgress(amount);
            }
        }
    }

    private UserQuest getOrCreateCurrentUserQuest(User user, Quest quest, LocalDate today) {
        // 업적과 resetCycle NONE 퀘스트는 기간이 없으므로 사용자당 한 행만 유지한다. — UserQuestService와 같은 기준
        if (quest.getQuestType() == QuestType.ACHIEVEMENT || quest.getResetCycle() == ResetCycle.NONE) {
            return userQuestRepository.findFirstByUserAndQuestAndDeletedFalse(user, quest)
                    .orElseGet(() -> userQuestRepository.save(
                            UserQuest.create(user, quest, LocalDateTime.now())
                    ));
        }

        LocalDateTime periodStart = getPeriodStart(quest.getResetCycle(), today);

        return userQuestRepository.findByUserAndQuestAndStartedAtAndDeletedFalse(user, quest, periodStart)
                .orElseGet(() -> userQuestRepository.save(
                        UserQuest.create(user, quest, periodStart)
                ));
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
}
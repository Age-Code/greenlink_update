package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.TargetType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// QuestRepository — JPA 데이터 접근
public interface QuestRepository extends JpaRepository<Quest, Long> {
    // find All By Deleted False 조회 — JPA query method
    List<Quest> findAllByDeletedFalse();

    // find All By Active True And Deleted False 조회 — JPA query method
    List<Quest> findAllByActiveTrueAndDeletedFalse();

    // find All By Quest Type And Active True And Deleted False 조회 — JPA query method
    List<Quest> findAllByQuestTypeAndActiveTrueAndDeletedFalse(QuestType questType);

    // find All By Target Type And Active True And Deleted False 조회 — JPA query method
    List<Quest> findAllByTargetTypeAndActiveTrueAndDeletedFalse(TargetType targetType);

    // find All By Quest Type And Target Type And Active True And Deleted False 조회 — JPA query method
    List<Quest> findAllByQuestTypeAndTargetTypeAndActiveTrueAndDeletedFalse(
            QuestType questType,
            TargetType targetType
    );

    // find By Id And Active True And Deleted False 조회 — JPA query method
    Optional<Quest> findByIdAndActiveTrueAndDeletedFalse(Long id);

    // exists By Title And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByTitleAndDeletedFalse(String title);
}

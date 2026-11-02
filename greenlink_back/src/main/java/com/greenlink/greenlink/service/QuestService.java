package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.quest.Quest;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.dto.QuestDto;
import com.greenlink.greenlink.repository.QuestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// QuestService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class QuestService {

    private final QuestRepository questRepository;

    public List<QuestDto.ListResDto> getQuests(QuestType questType) {
        List<Quest> quests;

        if (questType == null) {
            quests = questRepository.findAllByActiveTrueAndDeletedFalse();
        } else {
            quests = questRepository.findAllByQuestTypeAndActiveTrueAndDeletedFalse(questType);
        }

        return quests.stream()
                .map(QuestDto.ListResDto::from)
                .toList();
    }

    public QuestDto.DetailResDto getQuest(Long questId) {
        Quest quest = questRepository.findByIdAndActiveTrueAndDeletedFalse(questId)
                .orElseThrow(() -> new IllegalArgumentException("퀘스트를 찾을 수 없습니다."));

        return QuestDto.DetailResDto.from(quest);
    }
}
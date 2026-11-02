package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.dto.QuestDto;
import com.greenlink.greenlink.service.QuestService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// QuestController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/quests")
public class QuestController {

    private final QuestService questService;

    @GetMapping
    public ApiResponse<List<QuestDto.ListResDto>> getQuests(
            @RequestParam(required = false) QuestType questType
    ) {
        List<QuestDto.ListResDto> response = questService.getQuests(questType);

        return ApiResponse.success("퀘스트 목록 조회 성공", response);
    }

    @GetMapping("/{questId}")
    public ApiResponse<QuestDto.DetailResDto> getQuest(
            @PathVariable Long questId
    ) {
        QuestDto.DetailResDto response = questService.getQuest(questId);

        return ApiResponse.success("퀘스트 상세 조회 성공", response);
    }
}
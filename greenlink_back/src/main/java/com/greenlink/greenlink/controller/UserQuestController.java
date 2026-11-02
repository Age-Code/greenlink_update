package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.UserQuestStatus;
import com.greenlink.greenlink.dto.QuestDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.UserQuestService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// UserQuestController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-quests")
public class UserQuestController {

    private final UserQuestService userQuestService;

    @GetMapping
    public ApiResponse<List<QuestDto.UserQuestListResDto>> getUserQuests(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(required = false) QuestType questType,
            @RequestParam(required = false) UserQuestStatus status
    ) {
        List<QuestDto.UserQuestListResDto> response = userQuestService.getUserQuests(
                userDetails.getUserId(),
                questType,
                status
        );

        return ApiResponse.success("내 퀘스트 목록 조회 성공", response);
    }

    @GetMapping("/{userQuestId}")
    public ApiResponse<QuestDto.UserQuestDetailResDto> getUserQuest(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userQuestId
    ) {
        QuestDto.UserQuestDetailResDto response = userQuestService.getUserQuest(
                userDetails.getUserId(),
                userQuestId
        );

        return ApiResponse.success("내 퀘스트 상세 조회 성공", response);
    }

    // 퀘스트 보상 수령 처리
    @PostMapping("/{userQuestId}/reward")
    public ApiResponse<QuestDto.UserQuestRewardResDto> receiveReward(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userQuestId
    ) {
        QuestDto.UserQuestRewardResDto response = userQuestService.receiveReward(
                userDetails.getUserId(),
                userQuestId
        );

        return ApiResponse.success("퀘스트 보상을 수령했습니다.", response);
    }
}

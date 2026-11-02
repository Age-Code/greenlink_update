package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.AttendDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.AttendService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

// AttendController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/attends")
public class AttendController {

    private final AttendService attendService;

    // 오늘 출석 처리
    @PostMapping("/today")
    public ApiResponse<AttendDto.AttendTodayResDto> attendToday(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        AttendDto.AttendTodayResDto response = attendService.attendToday(userDetails.getUserId());

        return ApiResponse.success("출석이 완료되었습니다.", response);
    }

    @GetMapping
    public ApiResponse<AttendDto.AttendMonthResDto> getMyAttends(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        AttendDto.AttendMonthResDto response = attendService.getMyAttends(userDetails.getUserId(), year, month);

        return ApiResponse.success("출석 현황 조회 성공", response);
    }
}

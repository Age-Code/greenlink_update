package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.HomeDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.HomeService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

// HomeController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/home")
public class HomeController {

    private final HomeService homeService;

    @GetMapping
    public ApiResponse<HomeDto.ResDto> getHome(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        HomeDto.ResDto response = homeService.getHome(userDetails.getUserId());

        return ApiResponse.success("홈 데이터 조회 성공", response);
    }
}
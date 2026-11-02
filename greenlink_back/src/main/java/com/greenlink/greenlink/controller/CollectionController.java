package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.CollectionDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.CollectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// CollectionController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/collections")
public class CollectionController {

    private final CollectionService collectionService;

    @GetMapping
    public ApiResponse<List<CollectionDto.ListResDto>> getCollections(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        List<CollectionDto.ListResDto> response =
                collectionService.getCollections(userDetails.getUserId());

        return ApiResponse.success("도감 조회 성공", response);
    }

    @GetMapping("/{plantId}")
    public ApiResponse<CollectionDto.DetailResDto> getCollection(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long plantId
    ) {
        CollectionDto.DetailResDto response =
                collectionService.getCollection(userDetails.getUserId(), plantId);

        return ApiResponse.success("도감 상세 조회 성공", response);
    }
}
package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.dto.ItemDto;
import com.greenlink.greenlink.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// ItemController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/items")
public class ItemController {

    private final ItemService itemService;

    @GetMapping
    public ApiResponse<List<ItemDto.ListResDto>> getItems(
            @RequestParam(required = false) ItemType itemType
    ) {
        List<ItemDto.ListResDto> response = itemService.getItems(itemType);

        return ApiResponse.success("아이템 목록 조회 성공", response);
    }

    @GetMapping("/{itemId}")
    public ApiResponse<ItemDto.DetailResDto> getItem(
            @PathVariable Long itemId
    ) {
        ItemDto.DetailResDto response = itemService.getItem(itemId);

        return ApiResponse.success("아이템 상세 조회 성공", response);
    }
}
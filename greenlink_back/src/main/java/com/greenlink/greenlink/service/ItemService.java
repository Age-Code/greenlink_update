package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.dto.ItemDto;
import com.greenlink.greenlink.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// ItemService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ItemService {

    private final ItemRepository itemRepository;

    public List<ItemDto.ListResDto> getItems(ItemType itemType) {
        List<Item> items;

        if (itemType == null) {
            items = itemRepository.findAllByDeletedFalse();
        } else {
            items = itemRepository.findAllByItemTypeAndDeletedFalse(itemType);
        }

        return items.stream()
                .map(ItemDto.ListResDto::from)
                .toList();
    }

    public ItemDto.DetailResDto getItem(Long itemId) {
        Item item = itemRepository.findByIdAndDeletedFalse(itemId)
                .orElseThrow(() -> new IllegalArgumentException("아이템을 찾을 수 없습니다."));

        return ItemDto.DetailResDto.from(item);
    }
}
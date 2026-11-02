package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.ItemType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// ItemRepository — JPA 데이터 접근
public interface ItemRepository extends JpaRepository<Item, Long> {

    // find All By Deleted False 조회 — JPA query method
    List<Item> findAllByDeletedFalse();

    // find All By Item Type And Deleted False 조회 — JPA query method
    List<Item> findAllByItemTypeAndDeletedFalse(ItemType itemType);

    // find By Id And Deleted False 조회 — JPA query method
    Optional<Item> findByIdAndDeletedFalse(Long id);

    // find By Name And Deleted False 조회 — JPA query method
    Optional<Item> findByNameAndDeletedFalse(String name);

    // exists By Name And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByNameAndDeletedFalse(String name);
}

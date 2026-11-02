package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.item.UserItemStatus;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

// UserItemRepository — JPA 데이터 접근
public interface UserItemRepository extends JpaRepository<UserItem, Long> {

    // find By Id And User And Deleted False 조회 — JPA query method
    Optional<UserItem> findByIdAndUserAndDeletedFalse(Long id, User user);

    // exists By User And Item And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByUserAndItemAndDeletedFalse(User user, Item item);

    // find All By User And Deleted False 조회 — JPA query method
    List<UserItem> findAllByUserAndDeletedFalse(User user);

    // find All By User And Status And Deleted False 조회 — JPA query method
    List<UserItem> findAllByUserAndStatusAndDeletedFalse(
            User user,
            UserItemStatus status
    );

    // find All By User And Item Item Type And Deleted False 조회 — JPA query method
    List<UserItem> findAllByUserAndItem_ItemTypeAndDeletedFalse(
            User user,
            ItemType itemType
    );

    // find All By User And Item Item Type And Status And Deleted False 조회 — JPA query method
    List<UserItem> findAllByUserAndItem_ItemTypeAndStatusAndDeletedFalse(
            User user,
            ItemType itemType,
            UserItemStatus status
    );

    // find All By User And Item And Deleted False 조회 — JPA query method
    List<UserItem> findAllByUserAndItemAndDeletedFalse(
            User user,
            Item item
    );

    // count By User And Item And Status In And Deleted False 개수 조회 — JPA query method
    long countByUserAndItemAndStatusInAndDeletedFalse(
            User user,
            Item item,
            Collection<UserItemStatus> statuses
    );

    // count By User And Item And Status And Deleted False 개수 조회 — JPA query method
    long countByUserAndItemAndStatusAndDeletedFalse(
            User user,
            Item item,
            UserItemStatus status
    );

    // 식물에 장착된 특정 타입 아이템 조회 — 화분/아이템 해제용
    Optional<UserItem> findFirstByUserAndItem_ItemTypeAndUserPlantAndStatusAndDeletedFalse(
            User user,
            ItemType itemType,
            UserPlant userPlant,
            UserItemStatus status
    );

    // 식물에 장착된 특정 타입 아이템 목록 조회
    List<UserItem> findAllByUserAndItem_ItemTypeAndUserPlantAndStatusAndDeletedFalse(
            User user,
            ItemType itemType,
            UserPlant userPlant,
            UserItemStatus status
    );
}

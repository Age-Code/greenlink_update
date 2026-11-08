package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.item.UserItemStatus;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.UserItemDto;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

// UserItemService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserItemService {

    private final UserRepository userRepository;
    private final UserItemRepository userItemRepository;
    private final UserPlantRepository userPlantRepository;

    public List<UserItemDto.ListResDto> getUserItems(
            Long userId,
            ItemType itemType,
            UserItemStatus status
    ) {
        User user = findActiveUser(userId);

        List<UserItem> userItems = findUserItems(user, itemType, status);

        Map<Long, List<UserItem>> groupedByItemId = groupByItemId(userItems);

        // 수량 집계는 필터와 무관하게 전체 보유 아이템 기준 — 아이템 종류마다 count 쿼리를 3번씩 보내지 않고 한 번에 계산한다.
        Map<Long, Map<UserItemStatus, Long>> statusCountsByItemId =
                userItemRepository.findAllByUserAndDeletedFalse(user)
                        .stream()
                        .collect(Collectors.groupingBy(
                                userItem -> userItem.getItem().getId(),
                                Collectors.groupingBy(UserItem::getStatus, Collectors.counting())
                        ));

        return groupedByItemId.values()
                .stream()
                .map(groupedItems -> toUserItemListResponse(groupedItems, statusCountsByItemId))
                .toList();
    }

    // 화분 장착 처리
    @Transactional
    public UserItemDto.EquipPotResDto equipPot(
            Long userId,
            Long userItemId,
            UserItemDto.EquipPotReqDto request
    ) {
        User user = findActiveUser(userId);

        UserItem potUserItem = userItemRepository.findByIdAndUserAndDeletedFalse(userItemId, user)
                .orElseThrow(() -> new IllegalArgumentException("장착할 화분 아이템을 찾을 수 없습니다."));

        UserPlant userPlant = userPlantRepository.findByIdAndUserAndDeletedFalse(request.getUserPlantId(), user)
                .orElseThrow(() -> new IllegalArgumentException("장착 대상 식물을 찾을 수 없습니다."));

        validatePotCanBeEquipped(potUserItem);

        if (userPlant.getStatus() == UserPlantStatus.HARVESTED) {
            throw new IllegalStateException("수확이 끝난 식물에는 화분을 장착할 수 없습니다.");
        }

        unequipExistingPot(user, userPlant);

        potUserItem.equipPot(userPlant);

        return UserItemDto.EquipPotResDto.from(potUserItem);
    }

    // 화분 해제 처리
    @Transactional
    public UserItemDto.UnequipPotResDto unequipPot(
            Long userId,
            Long userItemId
    ) {
        User user = findActiveUser(userId);

        UserItem potUserItem = userItemRepository.findByIdAndUserAndDeletedFalse(userItemId, user)
                .orElseThrow(() -> new IllegalArgumentException("장착 해제할 화분 아이템을 찾을 수 없습니다."));

        validatePotCanBeUnequipped(potUserItem);

        potUserItem.unequipPot();

        return UserItemDto.UnequipPotResDto.from(potUserItem);
    }

    // 영양제 사용 처리
    @Transactional
    public UserItemDto.UseNutrientResDto useNutrient(
            Long userId,
            Long userItemId,
            UserItemDto.UseNutrientReqDto request
    ) {
        User user = findActiveUser(userId);

        UserItem nutrientUserItem = userItemRepository.findByIdAndUserAndDeletedFalse(userItemId, user)
                .orElseThrow(() -> new IllegalArgumentException("사용할 영양제 아이템을 찾을 수 없습니다."));

        UserPlant userPlant = userPlantRepository.findByIdAndUserAndDeletedFalse(request.getUserPlantId(), user)
                .orElseThrow(() -> new IllegalArgumentException("영양제를 사용할 식물을 찾을 수 없습니다."));

        validateNutrientCanBeUsed(nutrientUserItem);

        userPlant.applyNutrient(LocalDate.now());

        nutrientUserItem.useNutrient(userPlant);

        return UserItemDto.UseNutrientResDto.from(nutrientUserItem, userPlant, LocalDate.now());
    }

    // find User Items 조회 — 없으면 예외 또는 Optional 반환
    private List<UserItem> findUserItems(
            User user,
            ItemType itemType,
            UserItemStatus status
    ) {
        if (itemType == null && status == null) {
            return userItemRepository.findAllByUserAndDeletedFalse(user);
        }

        if (itemType != null && status == null) {
            return userItemRepository.findAllByUserAndItem_ItemTypeAndDeletedFalse(
                    user,
                    itemType
            );
        }

        if (itemType == null) {
            return userItemRepository.findAllByUserAndStatusAndDeletedFalse(
                    user,
                    status
            );
        }

        return userItemRepository.findAllByUserAndItem_ItemTypeAndStatusAndDeletedFalse(
                user,
                itemType,
                status
        );
    }

    // group By Item Id 처리
    private Map<Long, List<UserItem>> groupByItemId(List<UserItem> userItems) {
        return userItems.stream()
                .collect(
                        LinkedHashMap::new,
                        (map, userItem) -> map.computeIfAbsent(
                                userItem.getItem().getId(),
                                key -> new java.util.ArrayList<>()
                        ).add(userItem),
                        LinkedHashMap::putAll
                );
    }

    // to User Item List Response 처리
    private UserItemDto.ListResDto toUserItemListResponse(
            List<UserItem> groupedItems,
            Map<Long, Map<UserItemStatus, Long>> statusCountsByItemId
    ) {
        Item item = groupedItems.get(0).getItem();
        Map<UserItemStatus, Long> counts = statusCountsByItemId.getOrDefault(item.getId(), Map.of());

        long usableCount = counts.getOrDefault(UserItemStatus.OWNED, 0L);
        long equippedCount = counts.getOrDefault(UserItemStatus.EQUIPPED, 0L);
        long usedCount = counts.getOrDefault(UserItemStatus.USED, 0L);

        return UserItemDto.ListResDto.of(
                item,
                usableCount + equippedCount,
                usableCount,
                usedCount,
                groupedItems
        );
    }

    // unequip Existing Pot 처리
    private void unequipExistingPot(
            User user,
            UserPlant userPlant
    ) {
        userItemRepository
                .findAllByUserAndItem_ItemTypeAndUserPlantAndStatusAndDeletedFalse(
                        user,
                        ItemType.POT,
                        userPlant,
                        UserItemStatus.EQUIPPED
                )
                .forEach(UserItem::unequipPot);
    }

    // validate Pot Can Be Equipped 검증
    private void validatePotCanBeEquipped(UserItem userItem) {
        if (userItem.getItem().getItemType() != ItemType.POT) {
            throw new IllegalStateException("화분 아이템만 장착할 수 있습니다.");
        }

        if (userItem.getStatus() != UserItemStatus.OWNED) {
            throw new IllegalStateException("보유 중인 화분만 장착할 수 있습니다.");
        }
    }

    // validate Pot Can Be Unequipped 검증
    private void validatePotCanBeUnequipped(UserItem userItem) {
        if (userItem.getItem().getItemType() != ItemType.POT) {
            throw new IllegalStateException("화분 아이템만 장착 해제할 수 있습니다.");
        }

        if (userItem.getStatus() != UserItemStatus.EQUIPPED) {
            throw new IllegalStateException("장착 중인 화분만 해제할 수 있습니다.");
        }
    }

    // validate Nutrient Can Be Used 검증
    private void validateNutrientCanBeUsed(UserItem userItem) {
        if (userItem.getItem().getItemType() != ItemType.NUTRIENT) {
            throw new IllegalStateException("영양제 아이템만 사용할 수 있습니다.");
        }

        if (userItem.getStatus() != UserItemStatus.OWNED) {
            throw new IllegalStateException("보유 중인 영양제만 사용할 수 있습니다.");
        }
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

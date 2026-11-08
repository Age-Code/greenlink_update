package com.greenlink.greenlink.service;

import com.greenlink.greenlink.config.DefaultDataInitializer;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.dto.CollectionDto;
import com.greenlink.greenlink.dto.UserItemDto;
import com.greenlink.greenlink.dto.UserPlantDto;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

// 인벤토리 수량 집계와 도감 묶기가 한 번의 조회로 바뀐 뒤에도 같은 결과를 내는지
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class InventoryCollectionFlowTest {

    @Autowired
    private AuthService authService;
    @Autowired
    private UserPlantService userPlantService;
    @Autowired
    private UserItemService userItemService;
    @Autowired
    private CollectionService collectionService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private UserItemRepository userItemRepository;
    @Autowired
    private UserPlantRepository userPlantRepository;
    @Autowired
    private EntityManager entityManager;

    @Test
    void inventoryCountsAndCollectionReflectPlantingAndHarvest() {
        authService.signup(new AuthDto.SignupReqDto("inventory@example.com", "password", "inventory"));
        User user = userRepository.findByEmailAndDeletedFalse("inventory@example.com").orElseThrow();

        UserItem seed = userItemRepository.findAllByUserAndDeletedFalse(user).stream()
                .filter(item -> item.getItem().getName().equals(DefaultDataInitializer.DEFAULT_SEED_NAME))
                .findFirst()
                .orElseThrow();

        UserPlantDto.CreateResDto created = userPlantService.createUserPlant(
                user.getId(),
                new UserPlantDto.CreateReqDto(seed.getId(), "바질이")
        );

        // 씨앗 필터로 조회해도 수량은 전체 기준으로 계산된다.
        List<UserItemDto.ListResDto> seeds = userItemService.getUserItems(user.getId(), null, null).stream()
                .filter(group -> group.getName().equals(DefaultDataInitializer.DEFAULT_SEED_NAME))
                .toList();
        assertThat(seeds).hasSize(1);
        assertThat(seeds.get(0).getUsableCount()).isZero();
        assertThat(seeds.get(0).getUsedCount()).isEqualTo(1);

        UserItemDto.ListResDto pot = userItemService.getUserItems(user.getId(), null, null).stream()
                .filter(group -> group.getName().equals(DefaultDataInitializer.DEFAULT_POT_NAME))
                .findFirst()
                .orElseThrow();
        assertThat(pot.getOwnedCount()).isEqualTo(1);
        assertThat(pot.getUsableCount()).isEqualTo(1);

        // 수확 전에는 도감 미수집, 수확 후 수집
        assertThat(basil(user).isCollected()).isFalse();

        UserPlant plant = userPlantRepository.findById(created.getUserPlantId()).orElseThrow();
        ReflectionTestUtils.setField(plant, "status", UserPlantStatus.HARVESTED);
        ReflectionTestUtils.setField(plant, "harvestedAt", LocalDateTime.now());
        entityManager.flush();

        CollectionDto.ListResDto basil = basil(user);
        assertThat(basil.isCollected()).isTrue();
        assertThat(basil.getHarvestCount()).isEqualTo(1);
        assertThat(basil.getFirstHarvestedAt()).isNotNull();
    }

    private CollectionDto.ListResDto basil(User user) {
        return collectionService.getCollections(user.getId()).stream()
                .filter(item -> item.getName().equals("바질"))
                .findFirst()
                .orElseThrow();
    }
}

package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.CollectionDto;
import com.greenlink.greenlink.repository.PlantRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// CollectionService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CollectionService {

    private final UserRepository userRepository;
    private final PlantRepository plantRepository;
    private final UserPlantRepository userPlantRepository;

    public List<CollectionDto.ListResDto> getCollections(Long userId) {
        User user = findActiveUser(userId);

        List<Plant> plants = plantRepository.findAllByDeletedFalse();

        return plants.stream()
                .map(plant -> toCollectionListResponse(user, plant))
                .toList();
    }

    public CollectionDto.DetailResDto getCollection(Long userId, Long plantId) {
        User user = findActiveUser(userId);

        Plant plant = plantRepository.findByIdAndDeletedFalse(plantId)
                .orElseThrow(() -> new IllegalArgumentException("식물을 찾을 수 없습니다."));

        List<UserPlant> harvestedPlants =
                userPlantRepository.findAllByUserAndPlantAndStatusAndDeletedFalseOrderByHarvestedAtAsc(
                        user,
                        plant,
                        UserPlantStatus.HARVESTED
                );

        return CollectionDto.DetailResDto.of(plant, harvestedPlants);
    }

    // to Collection List Response 처리
    private CollectionDto.ListResDto toCollectionListResponse(User user, Plant plant) {
        List<UserPlant> harvestedPlants =
                userPlantRepository.findAllByUserAndPlantAndStatusAndDeletedFalseOrderByHarvestedAtAsc(
                        user,
                        plant,
                        UserPlantStatus.HARVESTED
                );

        boolean collected = !harvestedPlants.isEmpty();
        long harvestCount = harvestedPlants.size();

        LocalDateTime firstHarvestedAt = collected
                ? harvestedPlants.get(0).getHarvestedAt()
                : null;

        return CollectionDto.ListResDto.of(
                plant,
                collected,
                harvestCount,
                firstHarvestedAt
        );
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}
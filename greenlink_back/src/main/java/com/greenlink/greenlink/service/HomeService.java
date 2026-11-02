package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.HomeDto;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.EnumSet;

// HomeService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HomeService {

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;

    @Transactional
    public HomeDto.ResDto getHome(Long userId) {
        User user = findActiveUser(userId);
        LocalDate today = LocalDate.now();

        UserPlant mainUserPlant = findMainUserPlant(user);

        if (mainUserPlant != null) {
            mainUserPlant.refreshHarvestableStatus(today);
        }

        return HomeDto.ResDto.of(user, mainUserPlant, today);
    }

    // find Main User Plant 조회 — 없으면 예외 또는 Optional 반환
    private UserPlant findMainUserPlant(User user) {
        return userPlantRepository
                .findFirstByUserAndStatusInAndDeletedFalseOrderByCreatedAtDesc(
                        user,
                        EnumSet.of(
                                UserPlantStatus.GROWING,
                                UserPlantStatus.HARVESTABLE
                        )
                )
                .orElseGet(() ->
                        userPlantRepository
                                .findFirstByUserAndDeletedFalseOrderByCreatedAtDesc(user)
                                .orElse(null)
                );
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}
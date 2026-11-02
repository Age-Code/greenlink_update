package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// AutomationSettingRepository — JPA 데이터 접근
public interface AutomationSettingRepository extends JpaRepository<AutomationSetting, Long> {

    // 특정 식물의 자동화 설정 조회
    Optional<AutomationSetting> findByUserPlantAndDeletedFalse(
            UserPlant userPlant
    );

    // 특정 사용자의 특정 식물 자동화 설정 조회 — 사용자가 자기 식물의 자동화 설정만 조회/수정할 수 있도록 확인할 때 사용한다.
    Optional<AutomationSetting> findByUserAndUserPlantAndDeletedFalse(
            User user,
            UserPlant userPlant
    );

        // 특정 식물에 자동화 설정이 이미 존재하는지 확인

    boolean existsByUserPlantAndDeletedFalse(
            UserPlant userPlant
    );
}
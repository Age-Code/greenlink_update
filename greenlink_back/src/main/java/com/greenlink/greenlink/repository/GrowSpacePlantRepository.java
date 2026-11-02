package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// GrowSpacePlantRepository — JPA 데이터 접근
public interface GrowSpacePlantRepository extends JpaRepository<GrowSpacePlant, Long> {

    // find All By Grow Space And Deleted False 조회 — JPA query method
    List<GrowSpacePlant> findAllByGrowSpaceAndDeletedFalse(GrowSpace growSpace);

    // find All By Grow Space And Active True And Deleted False 조회 — JPA query method
    List<GrowSpacePlant> findAllByGrowSpaceAndActiveTrueAndDeletedFalse(GrowSpace growSpace);

    // find By User Plant And Deleted False 조회 — JPA query method
    Optional<GrowSpacePlant> findByUserPlantAndDeletedFalse(UserPlant userPlant);

    // find By User Plant And Active True And Deleted False 조회 — JPA query method
    Optional<GrowSpacePlant> findByUserPlantAndActiveTrueAndDeletedFalse(UserPlant userPlant);

    // find By Grow Space And User Plant And Deleted False 조회 — JPA query method
    Optional<GrowSpacePlant> findByGrowSpaceAndUserPlantAndDeletedFalse(
            GrowSpace growSpace,
            UserPlant userPlant
    );

    // exists By User Plant And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByUserPlantAndDeletedFalse(UserPlant userPlant);

    // exists By Grow Space And User Plant And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByGrowSpaceAndUserPlantAndDeletedFalse(
            GrowSpace growSpace,
            UserPlant userPlant
    );

    // 특정 재배 공간에 연결된 활성 식물 목록 조회 — 자동 LED 판단에서 growSpace 안의 식물 자동화 설정을 확인할 때 사용한다.
    List<GrowSpacePlant> findByGrowSpaceAndActiveTrueAndDeletedFalse(
            GrowSpace growSpace
    );


    // find Top By User Plant And Active True And Deleted False 조회 — JPA query method
    Optional<GrowSpacePlant> findTopByUserPlantAndActiveTrueAndDeletedFalse(
            UserPlant userPlant
    );
}

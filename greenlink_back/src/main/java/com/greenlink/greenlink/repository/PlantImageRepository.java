package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// PlantImageRepository — JPA 데이터 접근
public interface PlantImageRepository extends JpaRepository<PlantImage, Long> {

    // find By Id And Deleted False 조회 — JPA query method
    Optional<PlantImage> findByIdAndDeletedFalse(Long id);

    // find All By Grow Space And Deleted False Order By Captured At Desc 조회 — JPA query method
    List<PlantImage> findAllByGrowSpaceAndDeletedFalseOrderByCapturedAtDesc(
            GrowSpace growSpace
    );

    // find First By Grow Space And Deleted False Order By Captured At Desc 조회 — JPA query method
    Optional<PlantImage> findFirstByGrowSpaceAndDeletedFalseOrderByCapturedAtDesc(
            GrowSpace growSpace
    );

    // 공간 전체 사진(userPlant 없음) 중 최신 1건 — 다른 사용자 식물 사진이 섞이지 않도록 한다.
    Optional<PlantImage> findFirstByGrowSpaceAndUserPlantIsNullAndDeletedFalseOrderByCapturedAtDesc(
            GrowSpace growSpace
    );

    // find All By User Plant And Deleted False Order By Captured At Desc 조회 — JPA query method
    List<PlantImage> findAllByUserPlantAndDeletedFalseOrderByCapturedAtDesc(
            UserPlant userPlant
    );

    // find First By User Plant And Deleted False Order By Captured At Desc 조회 — JPA query method
    Optional<PlantImage> findFirstByUserPlantAndDeletedFalseOrderByCapturedAtDesc(
            UserPlant userPlant
    );

    // find All By Iot Device And Deleted False Order By Captured At Desc 조회 — JPA query method
    List<PlantImage> findAllByIotDeviceAndDeletedFalseOrderByCapturedAtDesc(
            IotDevice iotDevice
    );

    // find First By Iot Device And Deleted False Order By Captured At Desc 조회 — JPA query method
    Optional<PlantImage> findFirstByIotDeviceAndDeletedFalseOrderByCapturedAtDesc(
            IotDevice iotDevice
    );
}

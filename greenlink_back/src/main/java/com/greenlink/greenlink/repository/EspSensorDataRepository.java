package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

// EspSensorDataRepository — JPA 데이터 접근
public interface EspSensorDataRepository extends JpaRepository<EspSensorData, Long> {

    // find All By Grow Space And Deleted False Order By Measured At Desc 조회 — JPA query method
    List<EspSensorData> findAllByGrowSpaceAndDeletedFalseOrderByMeasuredAtDesc(
            GrowSpace growSpace
    );

    // find All By User Plant And Deleted False Order By Measured At Desc 조회 — JPA query method
    List<EspSensorData> findAllByUserPlantAndDeletedFalseOrderByMeasuredAtDesc(
            UserPlant userPlant
    );

    // find First By User Plant And Deleted False Order By Measured At Desc 조회 — JPA query method
    Optional<EspSensorData> findFirstByUserPlantAndDeletedFalseOrderByMeasuredAtDesc(
            UserPlant userPlant
    );

    // find All By Iot Device And Deleted False Order By Measured At Desc 조회 — JPA query method
    List<EspSensorData> findAllByIotDeviceAndDeletedFalseOrderByMeasuredAtDesc(
            IotDevice iotDevice
    );

    // find First By Iot Device And Deleted False Order By Measured At Desc 조회 — JPA query method
    Optional<EspSensorData> findFirstByIotDeviceAndDeletedFalseOrderByMeasuredAtDesc(
            IotDevice iotDevice
    );

    // find By User Plant And Measured At Between Order By Measured At Asc 조회 — JPA query method
    List<EspSensorData> findByUserPlantAndMeasuredAtBetweenOrderByMeasuredAtAsc(
            UserPlant userPlant,
            LocalDateTime start,
            LocalDateTime end
    );

    // find Top By User Plant And Measured At Less Than Equal Order By Measured At Desc 조회 — JPA query method
    Optional<EspSensorData> findTopByUserPlantAndMeasuredAtLessThanEqualOrderByMeasuredAtDesc(
            UserPlant userPlant,
            LocalDateTime measuredAt
    );

    // find Top By User Plant And Measured At Greater Than Equal Order By Measured At Asc 조회 — JPA query method
    Optional<EspSensorData> findTopByUserPlantAndMeasuredAtGreaterThanEqualOrderByMeasuredAtAsc(
            UserPlant userPlant,
            LocalDateTime measuredAt
    );
}

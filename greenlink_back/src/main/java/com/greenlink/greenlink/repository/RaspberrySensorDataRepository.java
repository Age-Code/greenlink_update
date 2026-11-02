package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

// RaspberrySensorDataRepository — JPA 데이터 접근
public interface RaspberrySensorDataRepository extends JpaRepository<RaspberrySensorData, Long> {

    // find All By Grow Space And Deleted False Order By Measured At Desc 조회 — JPA query method
    List<RaspberrySensorData> findAllByGrowSpaceAndDeletedFalseOrderByMeasuredAtDesc(
            GrowSpace growSpace
    );

    // find First By Grow Space And Deleted False Order By Measured At Desc 조회 — JPA query method
    Optional<RaspberrySensorData> findFirstByGrowSpaceAndDeletedFalseOrderByMeasuredAtDesc(
            GrowSpace growSpace
    );

    // find All By Iot Device And Deleted False Order By Measured At Desc 조회 — JPA query method
    List<RaspberrySensorData> findAllByIotDeviceAndDeletedFalseOrderByMeasuredAtDesc(
            IotDevice iotDevice
    );

    // find First By Iot Device And Deleted False Order By Measured At Desc 조회 — JPA query method
    Optional<RaspberrySensorData> findFirstByIotDeviceAndDeletedFalseOrderByMeasuredAtDesc(
            IotDevice iotDevice
    );

    // find By Grow Space And Measured At Between Order By Measured At Asc 조회 — JPA query method
    List<RaspberrySensorData> findByGrowSpaceAndMeasuredAtBetweenOrderByMeasuredAtAsc(
            GrowSpace growSpace,
            LocalDateTime start,
            LocalDateTime end
    );
}

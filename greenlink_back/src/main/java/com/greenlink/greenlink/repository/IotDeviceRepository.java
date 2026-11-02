package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// IotDeviceRepository — JPA 데이터 접근
public interface IotDeviceRepository extends JpaRepository<IotDevice, Long> {

    // find All By Deleted False 조회 — JPA query method
    List<IotDevice> findAllByDeletedFalse();

    // find All By Active True And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByActiveTrueAndDeletedFalse();

    // find By Id And Deleted False 조회 — JPA query method
    Optional<IotDevice> findByIdAndDeletedFalse(Long id);

    // find By Id And Active True And Deleted False 조회 — JPA query method
    Optional<IotDevice> findByIdAndActiveTrueAndDeletedFalse(Long id);

    // find By Device Key And Deleted False 조회 — JPA query method
    Optional<IotDevice> findByDeviceKeyAndDeletedFalse(String deviceKey);

    // find By Device Key And Active True And Deleted False 조회 — JPA query method
    Optional<IotDevice> findByDeviceKeyAndActiveTrueAndDeletedFalse(String deviceKey);

    // exists By Device Key And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByDeviceKeyAndDeletedFalse(String deviceKey);

    // find All By Grow Space And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByGrowSpaceAndDeletedFalse(GrowSpace growSpace);

    // find All By Grow Space And Active True And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByGrowSpaceAndActiveTrueAndDeletedFalse(GrowSpace growSpace);

    // find All By Grow Space And Device Type And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByGrowSpaceAndDeviceTypeAndDeletedFalse(
            GrowSpace growSpace,
            DeviceType deviceType
    );

    // find All By Grow Space And Device Type And Active True And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
            GrowSpace growSpace,
            DeviceType deviceType
    );

    // find First By Grow Space And Device Type And Active True And Deleted False 조회 — JPA query method
    Optional<IotDevice> findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
            GrowSpace growSpace,
            DeviceType deviceType
    );

    // find First By User Plant And Device Type And Active True And Deleted False 조회 — JPA query method
    Optional<IotDevice> findFirstByUserPlantAndDeviceTypeAndActiveTrueAndDeletedFalse(
            UserPlant userPlant,
            DeviceType deviceType
    );

    // find All By User Plant And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByUserPlantAndDeletedFalse(UserPlant userPlant);

    // find All By User Plant And Active True And Deleted False 조회 — JPA query method
    List<IotDevice> findAllByUserPlantAndActiveTrueAndDeletedFalse(UserPlant userPlant);

}

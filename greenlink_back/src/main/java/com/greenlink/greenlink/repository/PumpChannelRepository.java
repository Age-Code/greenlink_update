package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;

import java.util.List;
import java.util.Optional;

// PumpChannelRepository — JPA 데이터 접근
public interface PumpChannelRepository extends JpaRepository<PumpChannel, Long> {

    // find All By Deleted False 조회 — JPA query method
    List<PumpChannel> findAllByDeletedFalse();

    // find By Id And Deleted False 조회 — JPA query method
    Optional<PumpChannel> findByIdAndDeletedFalse(Long id);

    // find By Id And Active True And Deleted False 조회 — JPA query method
    Optional<PumpChannel> findByIdAndActiveTrueAndDeletedFalse(Long id);

    // find All By Grow Space And Deleted False 조회 — JPA query method
    List<PumpChannel> findAllByGrowSpaceAndDeletedFalse(GrowSpace growSpace);

    // find All By Grow Space And Active True And Deleted False 조회 — JPA query method
    List<PumpChannel> findAllByGrowSpaceAndActiveTrueAndDeletedFalse(GrowSpace growSpace);

    // find By User Plant And Deleted False 조회 — JPA query method
    Optional<PumpChannel> findByUserPlantAndDeletedFalse(UserPlant userPlant);

    // find By User Plant And Active True And Deleted False 조회 — JPA query method
    Optional<PumpChannel> findByUserPlantAndActiveTrueAndDeletedFalse(UserPlant userPlant);

    // 급수 명령 생성 직렬화용 — 같은 식물의 중복 검사 → 저장 사이에 다른 요청이 끼어들지 못하게 행 잠금
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<PumpChannel> findWithLockByUserPlantAndActiveTrueAndDeletedFalse(UserPlant userPlant);

    // exists By User Plant And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByUserPlantAndDeletedFalse(UserPlant userPlant);

    // find All By Raspberry Device And Deleted False 조회 — JPA query method
    List<PumpChannel> findAllByRaspberryDeviceAndDeletedFalse(IotDevice raspberryDevice);

    // find All By Raspberry Device And Active True And Deleted False 조회 — JPA query method
    List<PumpChannel> findAllByRaspberryDeviceAndActiveTrueAndDeletedFalse(IotDevice raspberryDevice);

    // find By Grow Space And User Plant And Active True And Deleted False 조회 — JPA query method
    Optional<PumpChannel> findByGrowSpaceAndUserPlantAndActiveTrueAndDeletedFalse(
            GrowSpace growSpace,
            UserPlant userPlant
    );
}

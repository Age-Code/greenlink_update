package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

// DeviceCommandRepository — JPA 데이터 접근
public interface DeviceCommandRepository extends JpaRepository<DeviceCommand, Long> {

    // 관리자 대시보드 — 전체 최근 명령, 실패 명령 수
    List<DeviceCommand> findTop15ByDeletedFalseOrderByRequestedAtDesc();

    long countByCommandStatusAndRequestedAtAfterAndDeletedFalse(
            CommandStatus commandStatus,
            LocalDateTime requestedAt
    );

    // 앱 최근 명령 이력 — 식물 명령과 공간 공용(조명) 명령을 함께 본다.
    List<DeviceCommand> findTop10ByGrowSpaceAndDeletedFalseOrderByRequestedAtDesc(GrowSpace growSpace);

    // 현재 조명 상태 추정 — 마지막으로 성공한 LIGHT_ON/LIGHT_OFF
    Optional<DeviceCommand> findTopByGrowSpaceAndCommandTypeInAndCommandStatusAndDeletedFalseOrderByCompletedAtDesc(
            GrowSpace growSpace,
            Collection<CommandType> commandTypes,
            CommandStatus commandStatus
    );

    // find By Id And Deleted False 조회 — JPA query method
    Optional<DeviceCommand> findByIdAndDeletedFalse(Long id);

    // find All By Grow Space And Deleted False Order By Requested At Desc 조회 — JPA query method
    List<DeviceCommand> findAllByGrowSpaceAndDeletedFalseOrderByRequestedAtDesc(
            GrowSpace growSpace
    );

    // find All By User Plant And Deleted False Order By Requested At Desc 조회 — JPA query method
    List<DeviceCommand> findAllByUserPlantAndDeletedFalseOrderByRequestedAtDesc(
            UserPlant userPlant
    );

    // find All By Iot Device And Deleted False Order By Requested At Asc 조회 — JPA query method
    List<DeviceCommand> findAllByIotDeviceAndDeletedFalseOrderByRequestedAtAsc(
            IotDevice iotDevice
    );

    // find All By Iot Device And Command Status And Deleted False Order By Requested At Asc 조회 — JPA query method
    List<DeviceCommand> findAllByIotDeviceAndCommandStatusAndDeletedFalseOrderByRequestedAtAsc(
            IotDevice iotDevice,
            CommandStatus commandStatus
    );

    // find All By Iot Device And Command Status In And Deleted False Order By Requested At Asc 조회 — JPA query method
    List<DeviceCommand> findAllByIotDeviceAndCommandStatusInAndDeletedFalseOrderByRequestedAtAsc(
            IotDevice iotDevice,
            Collection<CommandStatus> commandStatuses
    );

    // find All By Iot Device And Command Type And Command Status And Deleted False Order By Requested At Asc 조회 — JPA query method
    List<DeviceCommand> findAllByIotDeviceAndCommandTypeAndCommandStatusAndDeletedFalseOrderByRequestedAtAsc(
            IotDevice iotDevice,
            CommandType commandType,
            CommandStatus commandStatus
    );

    // exists By User Plant And Command Type And Command Status In And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
            UserPlant userPlant,
            CommandType commandType,
            Collection<CommandStatus> commandStatuses
    );

    // exists By Iot Device And Command Type And Command Status In And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByIotDeviceAndCommandTypeAndCommandStatusInAndDeletedFalse(
            IotDevice iotDevice,
            CommandType commandType,
            Collection<CommandStatus> commandStatuses
    );

    // exists By Pump Channel And Command Type And Command Status In And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByPumpChannelAndCommandTypeAndCommandStatusInAndDeletedFalse(
            PumpChannel pumpChannel,
            CommandType commandType,
            Collection<CommandStatus> commandStatuses
    );


    // 특정 식물의 미완료 명령 조회 — 방치 명령 정리에 사용한다.
    List<DeviceCommand> findAllByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
            UserPlant userPlant,
            CommandType commandType,
            Collection<CommandStatus> commandStatuses
    );

    // 특정 기기의 미완료 명령 조회 — 공간 단위 조명/센서 명령 정리에 사용한다.
    List<DeviceCommand> findAllByIotDeviceAndCommandTypeInAndCommandStatusInAndDeletedFalse(
            IotDevice iotDevice,
            Collection<CommandType> commandTypes,
            Collection<CommandStatus> commandStatuses
    );

    // 특정 식물의 특정 명령 타입 중 가장 최근 명령 조회 — 물 주기 쿨다운 확인에 사용한다.
    Optional<DeviceCommand> findTopByUserPlantAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
            UserPlant userPlant,
            CommandType commandType
    );

    // 특정 기기의 특정 명령 타입 중 가장 최근 명령 조회 — 공간 단위 조명 쿨다운 확인에 사용한다.
    Optional<DeviceCommand> findTopByIotDeviceAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
            IotDevice iotDevice,
            CommandType commandType
    );

    // 특정 기간의 식물별 명령 기록 조회 — 자동화 학습 데이터용
    List<DeviceCommand> findByUserPlantAndCommandTypeAndRequestedAtBetweenAndDeletedFalseOrderByRequestedAtAsc(
            UserPlant userPlant,
            CommandType commandType,
            LocalDateTime start,
            LocalDateTime end
    );
}

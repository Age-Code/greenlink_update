package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// 장치 명령 중복 판정 — 라즈베리파이가 응답하지 않아 방치된 명령은 취소하고 판정한다.
@Service
@RequiredArgsConstructor
@Transactional
public class DeviceCommandGuard {

    private static final String STALE_RESULT_MESSAGE = "장치 응답이 없어 자동으로 취소되었습니다.";

    private static final List<CommandStatus> RUNNING_STATUSES =
            List.of(CommandStatus.PENDING, CommandStatus.PROCESSING);

    private static final List<CommandType> LIGHT_COMMAND_TYPES =
            List.of(CommandType.LIGHT_ON, CommandType.LIGHT_OFF);

    private final DeviceCommandRepository deviceCommandRepository;

    // 식물의 진행 중 급수 명령 여부
    public boolean hasRunningWaterCommand(UserPlant userPlant) {
        return hasRunningCommand(
                deviceCommandRepository
                        .findAllByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
                                userPlant,
                                CommandType.WATER,
                                RUNNING_STATUSES
                        )
        );
    }

    // 재배 공간의 진행 중 조명 명령 여부 — LED는 공간당 1개이므로 기기 기준으로 판정한다.
    public boolean hasRunningLightCommand(IotDevice raspberryDevice) {
        return hasRunningCommand(
                deviceCommandRepository
                        .findAllByIotDeviceAndCommandTypeInAndCommandStatusInAndDeletedFalse(
                                raspberryDevice,
                                LIGHT_COMMAND_TYPES,
                                RUNNING_STATUSES
                        )
        );
    }

    // 재배 공간의 진행 중 센서 새로고침 명령 여부
    public boolean hasRunningSensorRefreshCommand(IotDevice raspberryDevice) {
        return hasRunningCommand(
                deviceCommandRepository
                        .findAllByIotDeviceAndCommandTypeInAndCommandStatusInAndDeletedFalse(
                                raspberryDevice,
                                List.of(CommandType.SENSOR_REFRESH),
                                RUNNING_STATUSES
                        )
        );
    }

    // 방치 명령을 취소한 뒤 남은 진행 중 명령 여부 반환
    private boolean hasRunningCommand(List<DeviceCommand> commands) {
        LocalDateTime now = LocalDateTime.now();
        boolean running = false;

        for (DeviceCommand command : commands) {
            if (command.isStale(now)) {
                command.cancel(STALE_RESULT_MESSAGE);
                continue;
            }

            running = true;
        }

        return running;
    }
}

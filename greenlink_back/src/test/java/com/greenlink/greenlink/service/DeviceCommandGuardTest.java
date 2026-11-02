package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class DeviceCommandGuardTest {

    @Mock
    private DeviceCommandRepository deviceCommandRepository;

    @InjectMocks
    private DeviceCommandGuard deviceCommandGuard;

    @Test
    void staleWaterCommandIsCancelledAndStopsBlockingNewCommand() {
        UserPlant userPlant = userPlant();
        DeviceCommand stale = waterCommand();
        makeStale(stale);

        given(deviceCommandRepository
                .findAllByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
                        eq(userPlant),
                        eq(CommandType.WATER),
                        any()
                ))
                .willReturn(List.of(stale));

        boolean running = deviceCommandGuard.hasRunningWaterCommand(userPlant);

        assertThat(running).isFalse();
        assertThat(stale.getCommandStatus()).isEqualTo(CommandStatus.CANCELLED);
    }

    @Test
    void recentWaterCommandStillBlocksNewCommand() {
        UserPlant userPlant = userPlant();
        DeviceCommand recent = waterCommand();

        given(deviceCommandRepository
                .findAllByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
                        eq(userPlant),
                        eq(CommandType.WATER),
                        any()
                ))
                .willReturn(List.of(recent));

        boolean running = deviceCommandGuard.hasRunningWaterCommand(userPlant);

        assertThat(running).isTrue();
        assertThat(recent.getCommandStatus()).isEqualTo(CommandStatus.PENDING);
    }

    @Test
    void lightCommandIsJudgedByDeviceAndStaleOneIsCancelled() {
        GrowSpace growSpace = GrowSpace.create("test-space", null);
        IotDevice raspberryDevice = raspberryPi(growSpace);
        DeviceCommand stale = DeviceCommand.createLightCommand(
                growSpace,
                null,
                raspberryDevice,
                CommandType.LIGHT_ON
        );
        makeStale(stale);

        given(deviceCommandRepository
                .findAllByIotDeviceAndCommandTypeInAndCommandStatusInAndDeletedFalse(
                        eq(raspberryDevice),
                        any(),
                        any()
                ))
                .willReturn(List.of(stale));

        boolean running = deviceCommandGuard.hasRunningLightCommand(raspberryDevice);

        assertThat(running).isFalse();
        assertThat(stale.getCommandStatus()).isEqualTo(CommandStatus.CANCELLED);
    }

    @Test
    void runningCommandAmongStaleOnesStillBlocks() {
        UserPlant userPlant = userPlant();
        DeviceCommand stale = waterCommand();
        makeStale(stale);
        DeviceCommand recent = waterCommand();

        given(deviceCommandRepository
                .findAllByUserPlantAndCommandTypeAndCommandStatusInAndDeletedFalse(
                        eq(userPlant),
                        eq(CommandType.WATER),
                        any()
                ))
                .willReturn(List.of(stale, recent));

        boolean running = deviceCommandGuard.hasRunningWaterCommand(userPlant);

        assertThat(running).isTrue();
        assertThat(stale.getCommandStatus()).isEqualTo(CommandStatus.CANCELLED);
        assertThat(recent.getCommandStatus()).isEqualTo(CommandStatus.PENDING);
    }

    private void makeStale(DeviceCommand command) {
        ReflectionTestUtils.setField(
                command,
                "requestedAt",
                LocalDateTime.now().minusMinutes(DeviceCommand.STALE_COMMAND_TIMEOUT_MINUTES + 1)
        );
    }

    private DeviceCommand waterCommand() {
        GrowSpace growSpace = GrowSpace.create("test-space", null);

        return DeviceCommand.createWaterCommand(
                growSpace,
                null,
                raspberryPi(growSpace),
                null
        );
    }

    private IotDevice raspberryPi(GrowSpace growSpace) {
        return IotDevice.createRaspberryPi(growSpace, "test-pi", "test-device-key");
    }

    private UserPlant userPlant() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);

        return UserPlant.create(user, plant, "바질이");
    }
}

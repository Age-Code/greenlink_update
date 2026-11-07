package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.quest.TargetType;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.iot.IotDeviceDto;
import com.greenlink.greenlink.repository.AutomationLogRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class IotCommandServiceTest {

    @Mock
    private IotDeviceRepository iotDeviceRepository;
    @Mock
    private DeviceCommandRepository deviceCommandRepository;
    @Mock
    private QuestProgressService questProgressService;
    @Mock
    private AutomationLogRepository automationLogRepository;

    @InjectMocks
    private IotCommandService iotCommandService;

    @Test
    void stalePendingCommandIsCancelledInsteadOfDelivered() {
        GrowSpace growSpace = GrowSpace.create("grower", null);
        IotDevice pi = IotDevice.createRaspberryPi(growSpace, "pi", "pi-key");
        UserPlant userPlant = userPlant();

        DeviceCommand stale = DeviceCommand.createLightCommand(growSpace, userPlant, pi, CommandType.LIGHT_ON);
        ReflectionTestUtils.setField(stale, "id", 1L);
        ReflectionTestUtils.setField(stale, "requestedAt", LocalDateTime.now().minusMinutes(30));

        DeviceCommand fresh = DeviceCommand.createLightCommand(growSpace, userPlant, pi, CommandType.LIGHT_OFF);
        ReflectionTestUtils.setField(fresh, "id", 2L);

        given(iotDeviceRepository.findByDeviceKeyAndActiveTrueAndDeletedFalse("pi-key"))
                .willReturn(Optional.of(pi));
        given(deviceCommandRepository.findAllByIotDeviceAndCommandStatusAndDeletedFalseOrderByRequestedAtAsc(
                pi,
                CommandStatus.PENDING
        )).willReturn(List.of(stale, fresh));

        List<IotDeviceDto.PendingCommandResDto> pending = iotCommandService.getPendingCommands("pi-key");

        // 오래된 명령은 Pi에 내려가지 않고 취소된다.
        assertThat(pending).extracting(IotDeviceDto.PendingCommandResDto::getCommandId).containsExactly(2L);
        assertThat(stale.getCommandStatus()).isEqualTo(CommandStatus.CANCELLED);
        assertThat(fresh.getCommandStatus()).isEqualTo(CommandStatus.PENDING);

        // 명령 polling도 장치 접속으로 기록한다.
        assertThat(pi.getLastConnectedAt()).isNotNull();
    }

    @Test
    void onlyManualWateringCountsTowardWateringQuest() {
        GrowSpace growSpace = GrowSpace.create("grower", null);
        IotDevice pi = IotDevice.createRaspberryPi(growSpace, "pi", "pi-key");
        UserPlant userPlant = userPlant();
        PumpChannel pump = PumpChannel.create(growSpace, userPlant, pi, "pump-1", 22, 1);
        ReflectionTestUtils.setField(pi, "id", 10L);

        DeviceCommand manual = processingWater(growSpace, userPlant, pi, pump, 1L);
        DeviceCommand automatic = processingWater(growSpace, userPlant, pi, pump, 2L);

        given(iotDeviceRepository.findByDeviceKeyAndActiveTrueAndDeletedFalse("pi-key")).willReturn(Optional.of(pi));
        given(deviceCommandRepository.findByIdAndDeletedFalse(1L)).willReturn(Optional.of(manual));
        given(deviceCommandRepository.findByIdAndDeletedFalse(2L)).willReturn(Optional.of(automatic));
        given(automationLogRepository.existsByCommandAndDeletedFalse(manual)).willReturn(false);
        given(automationLogRepository.existsByCommandAndDeletedFalse(automatic)).willReturn(true);

        iotCommandService.completeCommand("pi-key", 2L, new IotDeviceDto.CommandCompleteReqDto(true, "ok"));
        verify(questProgressService, never()).increaseProgress(any(), any(), anyInt());

        iotCommandService.completeCommand("pi-key", 1L, new IotDeviceDto.CommandCompleteReqDto(true, "ok"));
        verify(questProgressService).increaseProgress(eq(userPlant.getUser()), eq(TargetType.WATERING), eq(1));
    }

    private DeviceCommand processingWater(GrowSpace growSpace, UserPlant userPlant, IotDevice pi, PumpChannel pump, Long id) {
        DeviceCommand command = DeviceCommand.createWaterCommand(growSpace, userPlant, pi, pump);
        ReflectionTestUtils.setField(command, "id", id);
        command.markProcessing();
        return command;
    }

    private UserPlant userPlant() {
        User user = User.createUser("pi-test@example.com", "encoded", "tester");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);

        return UserPlant.create(user, plant, "바질이");
    }
}

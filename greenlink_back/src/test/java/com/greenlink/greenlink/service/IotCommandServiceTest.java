package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.iot.IotDeviceDto;
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
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class IotCommandServiceTest {

    @Mock
    private IotDeviceRepository iotDeviceRepository;
    @Mock
    private DeviceCommandRepository deviceCommandRepository;
    @Mock
    private QuestProgressService questProgressService;

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

    private UserPlant userPlant() {
        User user = User.createUser("pi-test@example.com", "encoded", "tester");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);

        return UserPlant.create(user, plant, "바질이");
    }
}

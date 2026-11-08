package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.repository.AutomationLogRepository;
import com.greenlink.greenlink.repository.AutomationModelRepository;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

// 자동 조명이 현재 LED 상태를 보고 판단하는지 — 밤새 OFF 반복, 켜짐/꺼짐 진동 방지
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AutomationLightStateTest {

    @Mock
    private AutomationSettingRepository automationSettingRepository;
    @Mock
    private AutomationLogRepository automationLogRepository;
    @Mock
    private AutomationModelRepository automationModelRepository;
    @Mock
    private DeviceCommandRepository deviceCommandRepository;
    @Mock
    private DeviceCommandGuard deviceCommandGuard;
    @Mock
    private IotDeviceRepository iotDeviceRepository;
    @Mock
    private GrowSpacePlantRepository growSpacePlantRepository;

    @InjectMocks
    private AutomationService automationService;

    private GrowSpace growSpace;
    private IotDevice pi;
    private UserPlant userPlant;

    @BeforeEach
    void setUp() {
        growSpace = GrowSpace.create("grower", null);
        pi = IotDevice.createRaspberryPi(growSpace, "pi", "pi-key");
        userPlant = userPlant();

        given(iotDeviceRepository.findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                growSpace,
                DeviceType.RASPBERRY_PI
        )).willReturn(Optional.of(pi));
        given(growSpacePlantRepository.findByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace))
                .willReturn(List.of(GrowSpacePlant.connect(growSpace, userPlant)));
        given(automationModelRepository.findTopByUserPlantAndModelStatusAndDeletedFalseOrderByLastTrainedAtDesc(
                any(),
                any()
        )).willReturn(Optional.empty());
        given(deviceCommandGuard.hasRunningLightCommand(pi)).willReturn(false);
        given(deviceCommandRepository.findTopByIotDeviceAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
                any(),
                any()
        )).willReturn(Optional.empty());
        given(deviceCommandRepository.save(any(DeviceCommand.class)))
                .willAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void ledOnDuringLightHoursIsKeptEvenIfMeasuredLuxIsHigh() {
        givenSetting(LocalTime.MIN, LocalTime.MAX);
        givenLastLight(CommandType.LIGHT_ON);

        // LED 빛 때문에 OFF 기준(500)을 넘는 조도 — 그래도 끄지 않는다.
        evaluate(900.0);

        verify(deviceCommandRepository, never()).save(any(DeviceCommand.class));
    }

    @Test
    void outsideLightHoursAlreadyOffDoesNotRepeatOffCommand() {
        givenOutsideLightHours();
        givenLastLight(CommandType.LIGHT_OFF);

        evaluate(0.0);

        verify(deviceCommandRepository, never()).save(any(DeviceCommand.class));
    }

    @Test
    void outsideLightHoursWhileOnTurnsLedOff() {
        givenOutsideLightHours();
        givenLastLight(CommandType.LIGHT_ON);

        evaluate(800.0);

        ArgumentCaptor<DeviceCommand> captor = ArgumentCaptor.forClass(DeviceCommand.class);
        verify(deviceCommandRepository).save(captor.capture());
        assertThat(captor.getValue().getCommandType()).isEqualTo(CommandType.LIGHT_OFF);
    }

    @Test
    void darkDuringLightHoursWhileOffTurnsLedOn() {
        givenSetting(LocalTime.MIN, LocalTime.MAX);
        givenLastLight(CommandType.LIGHT_OFF);

        evaluate(10.0);

        ArgumentCaptor<DeviceCommand> captor = ArgumentCaptor.forClass(DeviceCommand.class);
        verify(deviceCommandRepository).save(captor.capture());
        assertThat(captor.getValue().getCommandType()).isEqualTo(CommandType.LIGHT_ON);
    }

    private void evaluate(double lux) {
        automationService.evaluateAutoLight(
                RaspberrySensorData.create(growSpace, pi, 22.0, 50.0, lux, LocalDateTime.now())
        );
    }

    // 현재 시각을 포함하지 않는 1시간짜리 작동 시간대
    private void givenOutsideLightHours() {
        LocalTime start = LocalTime.now().plusHours(2).withMinute(0).withSecond(0).withNano(0);
        givenSetting(start, start.plusHours(1));
    }

    private void givenSetting(LocalTime start, LocalTime end) {
        given(automationSettingRepository.findByUserPlantAndDeletedFalse(any()))
                .willReturn(Optional.of(AutomationSetting.builder()
                        .autoLightEnabled(true)
                        .lightOnThresholdLux(300.0)
                        .lightOffThresholdLux(500.0)
                        .lightStartTime(start)
                        .lightEndTime(end)
                        .lightCooldownMinutes(10)
                        .build()));
    }

    private void givenLastLight(CommandType commandType) {
        given(deviceCommandRepository
                .findTopByGrowSpaceAndCommandTypeInAndCommandStatusAndDeletedFalseOrderByCompletedAtDesc(
                        any(),
                        any(),
                        any()
                ))
                .willReturn(Optional.of(DeviceCommand.createLightCommand(growSpace, userPlant, pi, commandType)));
    }

    private UserPlant userPlant() {
        User user = User.createUser("light@example.com", "encoded", "tester");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);

        return UserPlant.create(user, plant, "바질이");
    }
}

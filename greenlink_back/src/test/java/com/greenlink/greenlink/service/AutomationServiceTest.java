package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationLog;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AutomationServiceTest {

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

    @Test
    void sharedGrowSpaceLightCreatesOnlyOneCommandPerEvaluation() {
        GrowSpace growSpace = GrowSpace.create("test-space", null);
        IotDevice raspberryDevice = IotDevice.createRaspberryPi(growSpace, "test-pi", "test-device-key");

        UserPlant firstPlant = userPlant("바질이");
        UserPlant secondPlant = userPlant("해바라기");

        given(iotDeviceRepository.findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                growSpace,
                DeviceType.RASPBERRY_PI
        )).willReturn(Optional.of(raspberryDevice));

        given(growSpacePlantRepository.findByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace))
                .willReturn(List.of(
                        GrowSpacePlant.connect(growSpace, firstPlant),
                        GrowSpacePlant.connect(growSpace, secondPlant)
                ));

        given(automationSettingRepository.findByUserPlantAndDeletedFalse(any()))
                .willReturn(Optional.of(autoLightEnabledSetting()));

        // 학습 모델 없음 — 설정 임계치를 그대로 사용한다.
        given(automationModelRepository.findTopByUserPlantAndModelStatusAndDeletedFalseOrderByLastTrainedAtDesc(
                any(),
                any()
        )).willReturn(Optional.empty());

        given(deviceCommandGuard.hasRunningLightCommand(raspberryDevice)).willReturn(false);

        given(deviceCommandRepository.findTopByIotDeviceAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
                any(),
                any()
        )).willReturn(Optional.empty());

        given(deviceCommandRepository.save(any(DeviceCommand.class)))
                .willAnswer(invocation -> invocation.getArgument(0));
        given(automationLogRepository.save(any(AutomationLog.class)))
                .willAnswer(invocation -> invocation.getArgument(0));

        // ON 기준(300 lux)보다 낮은 조도 — 두 식물 모두 LIGHT_ON 조건을 만족한다.
        automationService.evaluateAutoLight(
                RaspberrySensorData.create(
                        growSpace,
                        raspberryDevice,
                        22.0,
                        50.0,
                        10.0,
                        LocalDateTime.now()
                )
        );

        // LED는 공간당 1개이므로 명령도 1건만 생성되어야 한다.
        verify(deviceCommandRepository, times(1)).save(any(DeviceCommand.class));
    }

    private AutomationSetting autoLightEnabledSetting() {
        return AutomationSetting.builder()
                .autoLightEnabled(true)
                .lightOnThresholdLux(300.0)
                .lightOffThresholdLux(500.0)
                .lightStartTime(LocalTime.MIN)
                .lightEndTime(LocalTime.MAX)
                .lightCooldownMinutes(10)
                .build();
    }

    private UserPlant userPlant(String nickname) {
        User user = User.createUser(nickname + "@example.com", "encoded-password", nickname);
        Plant plant = Plant.create("바질", "HERB", null, null, 30);

        return UserPlant.create(user, plant, nickname);
    }
}

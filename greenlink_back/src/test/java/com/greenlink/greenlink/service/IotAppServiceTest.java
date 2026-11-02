package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.iot.IotAppDto;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.EspSensorDataRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.PlantImageRepository;
import com.greenlink.greenlink.repository.RaspberrySensorDataRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class IotAppServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserPlantRepository userPlantRepository;
    @Mock
    private GrowSpacePlantRepository growSpacePlantRepository;
    @Mock
    private RaspberrySensorDataRepository raspberrySensorDataRepository;
    @Mock
    private EspSensorDataRepository espSensorDataRepository;
    @Mock
    private PlantImageRepository plantImageRepository;
    @Mock
    private AutomationSettingRepository automationSettingRepository;
    @Mock
    private DeviceCommandRepository deviceCommandRepository;

    @InjectMocks
    private IotAppService iotAppService;

    @Test
    void latestStatusBlocksWateringWhenSafetyModeThresholdIsReached() {
        // 안전 모드 ON, 기준 35% + 10% = 45% 이상이므로 차단된다.
        IotAppDto.IotLatestResDto response = getLatestStatusWith(
                setting(true, 35.0),
                50.0
        );

        assertThat(response.getWatering().isCanWater()).isFalse();
        assertThat(response.getWatering().getBlockReason()).contains("50.0%");
        assertThat(response.getWatering().getShortageThresholdPercent()).isEqualTo(35.0);
    }

    @Test
    void latestStatusAllowsWateringBelowSafetyThreshold() {
        IotAppDto.IotLatestResDto response = getLatestStatusWith(
                setting(true, 35.0),
                44.9
        );

        assertThat(response.getWatering().isCanWater()).isTrue();
        assertThat(response.getWatering().getBlockReason()).isNull();
    }

    @Test
    void latestStatusAllowsWateringWhenSafetyModeIsOff() {
        // 안전 모드가 꺼져 있으면 수분이 높아도 앱이 임의로 막지 않도록 허용을 내려준다.
        IotAppDto.IotLatestResDto response = getLatestStatusWith(
                setting(false, 35.0),
                85.0
        );

        assertThat(response.getWatering().isCanWater()).isTrue();
    }

    @Test
    void latestStatusAllowsWateringWhenAutomationSettingIsMissing() {
        IotAppDto.IotLatestResDto response = getLatestStatusWith(null, 85.0);

        assertThat(response.getWatering().isCanWater()).isTrue();
        assertThat(response.getWatering().getShortageThresholdPercent()).isEqualTo(35.0);
    }

    private IotAppDto.IotLatestResDto getLatestStatusWith(
            AutomationSetting setting,
            Double soilMoisturePercent
    ) {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);
        UserPlant userPlant = UserPlant.create(user, plant, "바질이");
        GrowSpace growSpace = GrowSpace.create("test-space", null);
        IotDevice raspberryDevice = IotDevice.createRaspberryPi(growSpace, "test-pi", "test-device-key");
        IotDevice espDevice = IotDevice.createEsp32(growSpace, userPlant, "test-esp", "test-esp-key");

        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(userPlantRepository.findByIdAndUserAndDeletedFalse(2L, user))
                .willReturn(Optional.of(userPlant));
        given(growSpacePlantRepository.findByUserPlantAndActiveTrueAndDeletedFalse(userPlant))
                .willReturn(Optional.of(GrowSpacePlant.connect(growSpace, userPlant)));
        given(raspberrySensorDataRepository
                .findFirstByGrowSpaceAndDeletedFalseOrderByMeasuredAtDesc(growSpace))
                .willReturn(Optional.empty());
        given(plantImageRepository.findFirstByUserPlantAndDeletedFalseOrderByCapturedAtDesc(userPlant))
                .willReturn(Optional.empty());
        given(plantImageRepository.findFirstByGrowSpaceAndUserPlantIsNullAndDeletedFalseOrderByCapturedAtDesc(growSpace))
                .willReturn(Optional.empty());
        given(automationSettingRepository.findByUserPlantAndDeletedFalse(userPlant))
                .willReturn(Optional.ofNullable(setting));

        EspSensorData latestSoil = EspSensorData.create(
                growSpace,
                userPlant,
                espDevice,
                2000,
                soilMoisturePercent,
                LocalDateTime.now()
        );

        given(espSensorDataRepository.findFirstByUserPlantAndDeletedFalseOrderByMeasuredAtDesc(userPlant))
                .willReturn(Optional.of(latestSoil));

        // 최신 사진이 없으므로 AI 이미지 조회는 일어나지 않는다.
        return iotAppService.getLatestIotStatus(1L, 2L);
    }

    private AutomationSetting setting(
            boolean wateringSafetyEnabled,
            Double waterThresholdPercent
    ) {
        return AutomationSetting.builder()
                .wateringSafetyEnabled(wateringSafetyEnabled)
                .waterThresholdPercent(waterThresholdPercent)
                .build();
    }
}

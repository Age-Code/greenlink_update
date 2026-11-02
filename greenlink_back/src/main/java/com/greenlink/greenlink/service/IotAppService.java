package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.ai.AiPlantImage;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.iot.IotAppDto;
import com.greenlink.greenlink.repository.AiPlantImageRepository;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.EspSensorDataRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.PlantImageRepository;
import com.greenlink.greenlink.repository.PumpChannelRepository;
import com.greenlink.greenlink.repository.RaspberrySensorDataRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// IoT 앱 서비스 — 수동 명령 생성, wateringSafetyEnabled 체크
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IotAppService {

    private static final double WATERING_SAFETY_MARGIN_PERCENT = 10.0;

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;

    private final GrowSpacePlantRepository growSpacePlantRepository;
    private final RaspberrySensorDataRepository raspberrySensorDataRepository;
    private final EspSensorDataRepository espSensorDataRepository;
    private final PlantImageRepository plantImageRepository;
    private final AiPlantImageRepository aiPlantImageRepository;
    private final PumpChannelRepository pumpChannelRepository;
    private final DeviceCommandRepository deviceCommandRepository;
    private final IotDeviceRepository iotDeviceRepository;
    private final AutomationSettingRepository automationSettingRepository;
    private final DeviceCommandGuard deviceCommandGuard;

    // 내 식물 IoT 최신 상태 조회
    public IotAppDto.IotLatestResDto getLatestIotStatus(
            Long userId,
            Long userPlantId
    ) {
        User user = findActiveUser(userId);

        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        GrowSpace growSpace = findGrowSpaceByUserPlant(userPlant);

        RaspberrySensorData latestEnvironment =
                raspberrySensorDataRepository
                        .findFirstByGrowSpaceAndDeletedFalseOrderByMeasuredAtDesc(growSpace)
                        .orElse(null);

        EspSensorData latestSoil =
                espSensorDataRepository
                        .findFirstByUserPlantAndDeletedFalseOrderByMeasuredAtDesc(userPlant)
                        .orElse(null);

        PlantImage latestImage =
                plantImageRepository
                        .findFirstByUserPlantAndDeletedFalseOrderByCapturedAtDesc(userPlant)
                        .orElseGet(() ->
                                plantImageRepository
                                        .findFirstByGrowSpaceAndUserPlantIsNullAndDeletedFalseOrderByCapturedAtDesc(growSpace)
                                        .orElse(null)
                        );

        AiPlantImage latestAiImage = null;

        if (latestImage != null) {
            latestAiImage = aiPlantImageRepository
                    .findTopByPlantImageAndDeletedFalseOrderByIdDesc(latestImage)
                    .orElse(null);
        }

        return IotAppDto.IotLatestResDto.of(
                userPlant.getId(),
                growSpace,
                latestEnvironment,
                latestSoil,
                latestImage,
                latestAiImage,
                resolveWateringStatus(userPlant)
        );
    }

    // 내 식물 사진 기록 조회
    public List<IotAppDto.PlantImageDto> getPlantImages(
            Long userId,
            Long userPlantId
    ) {
        User user = findActiveUser(userId);

        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        return plantImageRepository
                .findAllByUserPlantAndDeletedFalseOrderByCapturedAtDesc(userPlant)
                .stream()
                .map(plantImage -> {
                    AiPlantImage aiPlantImage = aiPlantImageRepository
                            .findTopByPlantImageAndDeletedFalseOrderByIdDesc(plantImage)
                            .orElse(null);

                    return IotAppDto.PlantImageDto.from(
                            plantImage,
                            aiPlantImage
                    );
                })
                .toList();
    }

    // 물 주기 요청
    @Transactional
    public IotAppDto.WaterCommandResDto requestWater(
            Long userId,
            Long userPlantId
    ) {
        User user = findActiveUser(userId);

        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        GrowSpace growSpace = findGrowSpaceByUserPlant(userPlant);

        PumpChannel pumpChannel = pumpChannelRepository
                .findWithLockByUserPlantAndActiveTrueAndDeletedFalse(userPlant)
                .orElseThrow(() -> new IllegalStateException("해당 식물에 연결된 펌프 채널이 없습니다."));

        validatePumpChannel(growSpace, userPlant, pumpChannel);

        validateNoPendingWaterCommand(userPlant);

        validateWateringSafety(userPlant);

        DeviceCommand command = DeviceCommand.createWaterCommand(
                growSpace,
                userPlant,
                pumpChannel.getRaspberryDevice(),
                pumpChannel
        );

        DeviceCommand savedCommand = deviceCommandRepository.save(command);

        return IotAppDto.WaterCommandResDto.from(savedCommand);
    }

    // 수동 조명 켜기 명령 생성
    @Transactional
    public IotAppDto.LightCommandResDto requestLightOn(
            Long userId,
            Long userPlantId
    ) {
        return requestLightCommand(
                userId,
                userPlantId,
                CommandType.LIGHT_ON
        );
    }

    // 수동 조명 끄기 명령 생성
    @Transactional
    public IotAppDto.LightCommandResDto requestLightOff(
            Long userId,
            Long userPlantId
    ) {
        return requestLightCommand(
                userId,
                userPlantId,
                CommandType.LIGHT_OFF
        );
    }

    // 수동 센서 새로고침 명령 생성 — 소유/공간/Pi 검증, 진행 중이면 409
    @Transactional
    public IotAppDto.DeviceCommandResDto requestSensorRefresh(
            Long userPlantId,
            Long userId
    ) {
        UserPlant userPlant = findUserPlantOrNotFound(userPlantId);

        User user = findActiveUser(userId);

        if (!userPlant.isOwner(user)) {
            throw new AccessDeniedException("해당 식물에 접근할 권한이 없습니다.");
        }

        GrowSpace growSpace = findGrowSpaceForSensorRefresh(userPlant);

        IotDevice raspberryDevice = iotDeviceRepository
                .findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                        growSpace,
                        DeviceType.RASPBERRY_PI
                )
                .orElseThrow(() -> new IllegalArgumentException("연결된 Pi 장치가 없습니다."));

        validateNoPendingSensorRefreshCommand(raspberryDevice);

        DeviceCommand command = DeviceCommand.createSensorRefreshCommand(
                growSpace,
                userPlant,
                raspberryDevice
        );

        DeviceCommand savedCommand = deviceCommandRepository.save(command);

        return IotAppDto.DeviceCommandResDto.fromSensorRefresh(savedCommand);
    }

    // request Light Command 요청 처리
    private IotAppDto.LightCommandResDto requestLightCommand(
            Long userId,
            Long userPlantId,
            CommandType commandType
    ) {
        User user = findActiveUser(userId);

        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        GrowSpace growSpace = findGrowSpaceByUserPlant(userPlant);

        IotDevice raspberryDevice = iotDeviceRepository
                .findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                        growSpace,
                        DeviceType.RASPBERRY_PI
                )
                .orElseThrow(() -> new IllegalStateException("재배 공간에 연결된 라즈베리파이가 없습니다."));

        validateNoPendingLightCommand(raspberryDevice);

        DeviceCommand command = DeviceCommand.createLightCommand(
                growSpace,
                userPlant,
                raspberryDevice,
                commandType
        );

        DeviceCommand savedCommand = deviceCommandRepository.save(command);

        return IotAppDto.LightCommandResDto.from(savedCommand);
    }

    // validate No Pending Light Command 검증 — 조명은 공간 공용 장치이므로 기기 단위로 판정한다.
    private void validateNoPendingLightCommand(IotDevice raspberryDevice) {
        if (deviceCommandGuard.hasRunningLightCommand(raspberryDevice)) {
            throw new IllegalStateException("이미 처리 중인 조명 명령이 있습니다.");
        }
    }

    // validate Pump Channel 검증
    private void validatePumpChannel(
            GrowSpace growSpace,
            UserPlant userPlant,
            PumpChannel pumpChannel
    ) {
        if (!pumpChannel.getGrowSpace().getId().equals(growSpace.getId())) {
            throw new IllegalStateException("펌프 채널이 해당 재배 공간에 속해 있지 않습니다.");
        }

        if (!pumpChannel.getUserPlant().getId().equals(userPlant.getId())) {
            throw new IllegalStateException("펌프 채널이 해당 식물에 연결되어 있지 않습니다.");
        }

        if (pumpChannel.getRaspberryDevice() == null) {
            throw new IllegalStateException("펌프 채널에 연결된 라즈베리파이가 없습니다.");
        }

        if (!pumpChannel.getRaspberryDevice().isRaspberryPi()) {
            throw new IllegalStateException("펌프 채널은 라즈베리파이 기기에 연결되어야 합니다.");
        }

        if (!pumpChannel.getRaspberryDevice().getActive()) {
            throw new IllegalStateException("라즈베리파이 기기가 비활성화되어 있습니다.");
        }
    }

    // validate No Pending Water Command 검증
    private void validateNoPendingWaterCommand(UserPlant userPlant) {
        if (deviceCommandGuard.hasRunningWaterCommand(userPlant)) {
            throw new IllegalStateException("이미 처리 중인 급수 명령이 있습니다.");
        }
    }

    // 과습 안전 모드 체크 — 서버 판정이 차단이면 400
    private void validateWateringSafety(UserPlant userPlant) {
        IotAppDto.WateringDto watering = resolveWateringStatus(userPlant);

        if (!watering.isCanWater()) {
            throw new IllegalArgumentException(watering.getBlockReason());
        }
    }

    // 급수 가능 여부 판정 — 최신 조회와 수동 급수가 같은 기준을 쓰도록 한곳에서 계산한다.
    private IotAppDto.WateringDto resolveWateringStatus(UserPlant userPlant) {
        AutomationSetting setting = automationSettingRepository
                .findByUserPlantAndDeletedFalse(userPlant)
                .orElse(null);

        Double waterThreshold = setting == null || setting.getWaterThresholdPercent() == null
                ? 35.0
                : setting.getWaterThresholdPercent();

        if (setting == null || !setting.isWateringSafetyEnabled()) {
            return IotAppDto.WateringDto.allowed(waterThreshold);
        }

        EspSensorData latestSoil = espSensorDataRepository
                .findFirstByUserPlantAndDeletedFalseOrderByMeasuredAtDesc(userPlant)
                .orElse(null);

        if (latestSoil == null || latestSoil.getSoilMoisturePercent() == null) {
            return IotAppDto.WateringDto.allowed(waterThreshold);
        }

        double safetyThreshold = waterThreshold + WATERING_SAFETY_MARGIN_PERCENT;

        if (latestSoil.getSoilMoisturePercent() >= safetyThreshold) {
            return IotAppDto.WateringDto.blocked(
                    waterThreshold,
                    String.format(
                            "토양 수분이 %.1f%%로 충분하여 급수가 차단되었습니다.",
                            latestSoil.getSoilMoisturePercent()
                    )
            );
        }

        return IotAppDto.WateringDto.allowed(waterThreshold);
    }

    // validate No Pending Sensor Refresh Command 검증
    private void validateNoPendingSensorRefreshCommand(IotDevice raspberryDevice) {
        if (deviceCommandGuard.hasRunningSensorRefreshCommand(raspberryDevice)) {
            throw new IllegalStateException("이미 센서 새로고침이 진행 중입니다.");
        }
    }

    // find Grow Space For Sensor Refresh 조회 — 없으면 예외 또는 Optional 반환
    private GrowSpace findGrowSpaceForSensorRefresh(UserPlant userPlant) {
        GrowSpacePlant growSpacePlant = growSpacePlantRepository
                .findByUserPlantAndActiveTrueAndDeletedFalse(userPlant)
                .orElseThrow(() -> new IllegalArgumentException("재배 공간이 연결되지 않았습니다"));

        return growSpacePlant.getGrowSpace();
    }

    // find Grow Space By User Plant 조회 — 없으면 예외 또는 Optional 반환
    private GrowSpace findGrowSpaceByUserPlant(UserPlant userPlant) {
        GrowSpacePlant growSpacePlant = growSpacePlantRepository
                .findByUserPlantAndActiveTrueAndDeletedFalse(userPlant)
                .orElseThrow(() -> new IllegalStateException("해당 식물이 재배 공간에 연결되어 있지 않습니다."));

        return growSpacePlant.getGrowSpace();
    }

    // find My User Plant 조회 — 없으면 예외 또는 Optional 반환
    private UserPlant findMyUserPlant(
            Long userPlantId,
            User user
    ) {
        return userPlantRepository.findByIdAndUserAndDeletedFalse(userPlantId, user)
                .orElseThrow(() -> new IllegalArgumentException("식물을 찾을 수 없습니다."));
    }

    // UserPlant 조회 — 없으면 404
    private UserPlant findUserPlantOrNotFound(Long userPlantId) {
        return userPlantRepository.findByIdAndDeletedFalse(userPlantId)
                .orElseThrow(() -> new EntityNotFoundException("식물을 찾을 수 없습니다."));
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

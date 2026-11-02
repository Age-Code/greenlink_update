package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationDecisionMode;
import com.greenlink.greenlink.domain.automation.AutomationLog;
import com.greenlink.greenlink.domain.automation.AutomationModel;
import com.greenlink.greenlink.domain.automation.AutomationModelStatus;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.automation.AutomationType;
import com.greenlink.greenlink.domain.automation.TriggerSensorType;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AutomationDto;
import com.greenlink.greenlink.repository.AutomationLogRepository;
import com.greenlink.greenlink.repository.AutomationModelRepository;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.PumpChannelRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

// 자동화 서비스 — 센서 저장 후 자동 급수/조명 판단 및 명령 생성
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AutomationService {

    private static final double MODEL_CONFIDENCE_THRESHOLD = 0.6;
    private static final double WATERING_SAFETY_MARGIN_PERCENT = 10.0;

    private final AutomationSettingRepository automationSettingRepository;
    private final AutomationLogRepository automationLogRepository;
    private final AutomationModelRepository automationModelRepository;

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;

    private final DeviceCommandRepository deviceCommandRepository;
    private final DeviceCommandGuard deviceCommandGuard;
    private final PumpChannelRepository pumpChannelRepository;
    private final IotDeviceRepository iotDeviceRepository;
    private final GrowSpacePlantRepository growSpacePlantRepository;

    // 자동화 설정 조회 — 설정이 없으면 기본 설정을 생성해서 반환한다.
    @Transactional
    public AutomationDto.SettingResDto getSetting(
            Long userId,
            Long userPlantId
    ) {
        User user = findActiveUser(userId);
        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        AutomationSetting setting = getOrCreateDefaultSetting(user, userPlant);

        return AutomationDto.SettingResDto.from(setting);
    }

    // 자동화 설정 수정
    @Transactional
    public AutomationDto.SettingResDto updateSetting(
            Long userId,
            Long userPlantId,
            AutomationDto.UpdateSettingReqDto request
    ) {
        User user = findActiveUser(userId);
        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        AutomationSetting setting = getOrCreateDefaultSetting(user, userPlant);

        validateSettingRequest(request);

        setting.updateSetting(
                request.getAutoWaterEnabled(),
                request.getAutoLightEnabled(),
                request.getWaterThresholdPercent(),
                request.getWaterCooldownMinutes(),
                request.getLightOnThresholdLux(),
                request.getLightOffThresholdLux(),
                request.getLightStartTime(),
                request.getLightEndTime(),
                request.getLightCooldownMinutes(),
                request.getAutoOptimizeEnabled(),
                request.getDecisionMode(),
                request.getMinLearningDataCount()
        );

        if (request.getWateringSafetyEnabled() != null) {
            setting.updateWateringSafetyEnabled(request.getWateringSafetyEnabled());
        }

        return AutomationDto.SettingResDto.from(setting);
    }

    // 자동화 로그 조회
    public List<AutomationDto.LogResDto> getLogs(
            Long userId,
            Long userPlantId
    ) {
        User user = findActiveUser(userId);
        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        return automationLogRepository
                .findTop5ByUserPlantAndDeletedFalseOrderByCreatedAtDesc(userPlant)
                .stream()
                .map(AutomationDto.LogResDto::from)
                .toList();
    }

    // ESP 토양수분 데이터 저장 직후 호출된다. — 학습 모델 기준값이 사용 가능하면 학습 기준값을 사용하고,
    @Transactional
    public void evaluateAutoWater(EspSensorData sensorData) {
        if (sensorData == null) {
            log.debug("[AUTO_WATER] SKIP — sensorData=null");
            return;
        }

        UserPlant userPlant = sensorData.getUserPlant();

        if (userPlant == null) {
            log.debug("[AUTO_WATER] SKIP — userPlant=null");
            return;
        }

        User user = userPlant.getUser();

        if (user == null) {
            log.debug("[AUTO_WATER] SKIP — user=null (userPlantId={})", userPlant.getId());
            return;
        }

        GrowSpace growSpace = sensorData.getGrowSpace();

        if (growSpace == null) {
            log.debug("[AUTO_WATER] SKIP — growSpace=null (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.DEVICE_NOT_READY,
                    sensorData.getSoilMoisturePercent(),
                    null,
                    "재배 공간 정보가 없어 자동 급수를 건너뜁니다."
            );
            return;
        }

        AutomationSetting setting = getOrCreateDefaultSetting(user, userPlant);

        Double soilMoisturePercent = sensorData.getSoilMoisturePercent();
        Double waterThreshold = resolveWaterThreshold(userPlant, setting);

        if (soilMoisturePercent == null) {
            log.debug("[AUTO_WATER] SKIP — soilMoisturePercent=null (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.SOIL_MOISTURE,
                    null,
                    waterThreshold,
                    "토양수분 퍼센트 값이 없어 자동 급수를 건너뜁니다."
            );
            return;
        }

        if (!Boolean.TRUE.equals(setting.getAutoWaterEnabled())) {
            log.debug("[AUTO_WATER] SKIP — autoWaterEnabled=false (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.DISABLED,
                    soilMoisturePercent,
                    waterThreshold,
                    "자동 물 주기가 꺼져 있어 자동 급수를 실행하지 않습니다."
            );
            return;
        }

        log.debug("[AUTO_WATER] autoWaterEnabled=true, 판단 시작 (userPlantId={})", userPlant.getId());
        log.debug("[AUTO_WATER] 수분={}%, 임계치={}%", soilMoisturePercent, waterThreshold);

        if (soilMoisturePercent > waterThreshold) {
            log.debug("[AUTO_WATER] SKIP — 수분이 임계치보다 높아 급수 불필요 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.SOIL_MOISTURE,
                    soilMoisturePercent,
                    waterThreshold,
                    "토양수분이 기준값보다 높아 자동 급수를 실행하지 않습니다."
            );
            return;
        }

        if (setting.isWateringSafetyEnabled()) {
            double safetyThreshold = resolveWateringSafetyThreshold(setting);

            log.debug("[AUTO_WATER] 과습 안전 모드 체크: 수분={}%, safetyThreshold={}% (userPlantId={})",
                    soilMoisturePercent, safetyThreshold, userPlant.getId());

            if (soilMoisturePercent >= safetyThreshold) {
                log.debug("[AUTO_WATER] SKIP — 과습 안전 모드로 급수 차단 (userPlantId={})", userPlant.getId());
                saveSkipLog(
                        userPlant,
                        AutomationType.SKIP_WATER,
                        TriggerSensorType.SOIL_MOISTURE,
                        soilMoisturePercent,
                        safetyThreshold,
                        String.format(
                                "과습 안전 모드: 토양 수분 %.1f%%로 급수 차단",
                                soilMoisturePercent
                        )
                );
                return;
            }
        }

        // 수동 급수와 같은 펌프 채널 행 잠금으로 중복 검사 → 명령 저장을 직렬화한다.
        pumpChannelRepository.findWithLockByUserPlantAndActiveTrueAndDeletedFalse(userPlant);

        if (deviceCommandGuard.hasRunningWaterCommand(userPlant)) {
            log.debug("[AUTO_WATER] SKIP — 진행 중 WATER 명령 존재 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.COMMAND_DUPLICATED,
                    soilMoisturePercent,
                    waterThreshold,
                    "이미 처리 대기 또는 처리 중인 급수 명령이 있어 자동 급수를 건너뜁니다."
            );
            return;
        }

        log.debug("[AUTO_WATER] cooldown 체크: 마지막 급수 후 경과 시간 확인 (userPlantId={})", userPlant.getId());

        if (isRecentlyCommandCreated(
                userPlant,
                CommandType.WATER,
                setting.getWaterCooldownMinutes()
        )) {
            log.debug("[AUTO_WATER] SKIP — cooldown 미경과 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.COOLDOWN,
                    soilMoisturePercent,
                    waterThreshold,
                    "최근 급수 명령이 있어 쿨다운 시간 동안 자동 급수를 건너뜁니다."
            );
            return;
        }

        IotDevice raspberryDevice = iotDeviceRepository
                .findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                        growSpace,
                        DeviceType.RASPBERRY_PI
                )
                .orElse(null);

        if (raspberryDevice == null) {
            log.debug("[AUTO_WATER] SKIP — 활성 Pi 없음 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.DEVICE_NOT_READY,
                    soilMoisturePercent,
                    waterThreshold,
                    "재배 공간에 연결된 라즈베리파이가 없어 자동 급수를 건너뜁니다."
            );
            return;
        }

        PumpChannel pumpChannel = pumpChannelRepository
                .findByGrowSpaceAndUserPlantAndActiveTrueAndDeletedFalse(
                        growSpace,
                        userPlant
                )
                .orElse(null);

        if (pumpChannel == null) {
            log.debug("[AUTO_WATER] SKIP — 펌프 채널 없음 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_WATER,
                    TriggerSensorType.DEVICE_NOT_READY,
                    soilMoisturePercent,
                    waterThreshold,
                    "식물에 연결된 펌프 채널이 없어 자동 급수를 건너뜁니다."
            );
            return;
        }

        DeviceCommand command = DeviceCommand.createWaterCommand(
                growSpace,
                userPlant,
                raspberryDevice,
                pumpChannel
        );

        DeviceCommand savedCommand = deviceCommandRepository.save(command);

        log.info("[AUTO_WATER] WATER 명령 생성 완료 (commandId={}, userPlantId={})",
                savedCommand.getId(), userPlant.getId());

        saveExecutedLog(
                userPlant,
                AutomationType.AUTO_WATER,
                TriggerSensorType.SOIL_MOISTURE,
                soilMoisturePercent,
                waterThreshold,
                savedCommand,
                "토양수분 "
                        + soilMoisturePercent
                        + "%가 기준 "
                        + waterThreshold
                        + "% 이하라 자동 급수 명령을 생성했습니다."
        );
    }

    // Raspberry 환경 데이터 저장 직후 호출된다. — 학습 모델 기준값이 사용 가능하면 학습 조도 기준값을 사용하고,
    @Transactional
    public void evaluateAutoLight(RaspberrySensorData sensorData) {
        if (sensorData == null) {
            log.debug("[AUTO_LIGHT] SKIP — sensorData=null");
            return;
        }

        GrowSpace growSpace = sensorData.getGrowSpace();

        if (growSpace == null) {
            log.debug("[AUTO_LIGHT] SKIP — growSpace=null");
            return;
        }

        Double light = sensorData.getLight();

        if (light == null) {
            log.debug("[AUTO_LIGHT] SKIP — light=null (growSpaceId={})", growSpace.getId());
            return;
        }

        log.debug("[AUTO_LIGHT] 판단 시작: 조도={} lux (growSpaceId={})", light, growSpace.getId());

        IotDevice raspberryDevice = iotDeviceRepository
                .findFirstByGrowSpaceAndDeviceTypeAndActiveTrueAndDeletedFalse(
                        growSpace,
                        DeviceType.RASPBERRY_PI
                )
                .orElse(null);

        if (raspberryDevice == null) {
            log.debug("[AUTO_LIGHT] SKIP — 활성 Pi 없음 (growSpaceId={})", growSpace.getId());
            return;
        }

        List<GrowSpacePlant> growSpacePlants =
                growSpacePlantRepository.findByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace);

        if (growSpacePlants.isEmpty()) {
            log.debug("[AUTO_LIGHT] SKIP — growSpace에 활성 식물 없음 (growSpaceId={})", growSpace.getId());
            return;
        }

        for (GrowSpacePlant growSpacePlant : growSpacePlants) {
            UserPlant userPlant = growSpacePlant.getUserPlant();

            if (userPlant == null || userPlant.getUser() == null) {
                log.debug("[AUTO_LIGHT] SKIP — userPlant 또는 user 없음 (growSpaceId={})", growSpace.getId());
                continue;
            }

            boolean commandCreated = evaluateAutoLightForUserPlant(
                    userPlant,
                    growSpace,
                    raspberryDevice,
                    light
            );

            // LED는 공간당 1개이므로 이번 주기의 조명은 먼저 판단된 식물 설정으로 결정한다.
            if (commandCreated) {
                log.debug("[AUTO_LIGHT] 공간 조명 명령이 생성되어 나머지 식물 판단을 건너뜁니다 (growSpaceId={}, 기준 userPlantId={})",
                        growSpace.getId(), userPlant.getId());
                return;
            }
        }
    }

    // 특정 식물 기준으로 자동 LED 판단 — 명령을 생성했으면 true를 반환한다.
    private boolean evaluateAutoLightForUserPlant(
            UserPlant userPlant,
            GrowSpace growSpace,
            IotDevice raspberryDevice,
            Double light
    ) {
        AutomationSetting setting =
                getOrCreateDefaultSetting(userPlant.getUser(), userPlant);

        Double lightOnThreshold = resolveLightOnThreshold(userPlant, setting);
        Double lightOffThreshold = resolveLightOffThreshold(userPlant, setting);

        if (!Boolean.TRUE.equals(setting.getAutoLightEnabled())) {
            log.debug("[AUTO_LIGHT] SKIP — autoLightEnabled=false (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_LIGHT,
                    TriggerSensorType.DISABLED,
                    light,
                    lightOnThreshold,
                    "자동 조명이 꺼져 있어 자동 조명 제어를 실행하지 않습니다."
            );
            return false;
        }

        log.debug("[AUTO_LIGHT] autoLightEnabled=true, 판단 시작 (userPlantId={})", userPlant.getId());
        log.debug("[AUTO_LIGHT] 조도={}, ON임계치={}, OFF임계치={} (userPlantId={})",
                light, lightOnThreshold, lightOffThreshold, userPlant.getId());

        LocalTime now = LocalTime.now();

        boolean inLightTime = isTimeWithinRange(
                now,
                setting.getLightStartTime(),
                setting.getLightEndTime()
        );

        log.debug("[AUTO_LIGHT] 시간대 체크: 현재={}, 허용={}~{} (userPlantId={})",
                now, setting.getLightStartTime(), setting.getLightEndTime(), userPlant.getId());

        if (!inLightTime) {
            log.debug("[AUTO_LIGHT] 시간대 외 — LIGHT_OFF 판단 진행 (userPlantId={})", userPlant.getId());
            return createLightCommandIfPossible(
                    userPlant,
                    growSpace,
                    raspberryDevice,
                    CommandType.LIGHT_OFF,
                    AutomationType.AUTO_LIGHT_OFF,
                    TriggerSensorType.TIME,
                    light,
                    lightOffThreshold,
                    setting.getLightCooldownMinutes(),
                    "자동 조명 작동 시간이 아니므로 LED OFF 명령을 생성했습니다."
            );
        }

        if (light <= lightOnThreshold) {
            log.debug("[AUTO_LIGHT] LIGHT_ON 조건 충족 (userPlantId={})", userPlant.getId());
            return createLightCommandIfPossible(
                    userPlant,
                    growSpace,
                    raspberryDevice,
                    CommandType.LIGHT_ON,
                    AutomationType.AUTO_LIGHT_ON,
                    TriggerSensorType.LIGHT,
                    light,
                    lightOnThreshold,
                    setting.getLightCooldownMinutes(),
                    "조도 "
                            + light
                            + " lux가 ON 기준 "
                            + lightOnThreshold
                            + " lux 이하라 LED ON 명령을 생성했습니다."
            );
        }

        if (light >= lightOffThreshold) {
            log.debug("[AUTO_LIGHT] LIGHT_OFF 조건 충족 (userPlantId={})", userPlant.getId());
            return createLightCommandIfPossible(
                    userPlant,
                    growSpace,
                    raspberryDevice,
                    CommandType.LIGHT_OFF,
                    AutomationType.AUTO_LIGHT_OFF,
                    TriggerSensorType.LIGHT,
                    light,
                    lightOffThreshold,
                    setting.getLightCooldownMinutes(),
                    "조도 "
                            + light
                            + " lux가 OFF 기준 "
                            + lightOffThreshold
                            + " lux 이상이라 LED OFF 명령을 생성했습니다."
            );
        }

        log.debug("[AUTO_LIGHT] SKIP — 조도값이 제어 구간 밖 (userPlantId={})", userPlant.getId());

        saveSkipLog(
                userPlant,
                AutomationType.SKIP_LIGHT,
                TriggerSensorType.LIGHT,
                light,
                lightOnThreshold,
                "조도값이 자동 조명 제어 구간에 해당하지 않아 명령을 생성하지 않습니다."
        );

        return false;
    }

    // LIGHT_ON / LIGHT_OFF 명령 생성 공통 로직 — 생성했으면 true를 반환한다.
    private boolean createLightCommandIfPossible(
            UserPlant userPlant,
            GrowSpace growSpace,
            IotDevice raspberryDevice,
            CommandType commandType,
            AutomationType automationType,
            TriggerSensorType triggerSensorType,
            Double triggerValue,
            Double thresholdValue,
            Integer cooldownMinutes,
            String successMessage
    ) {
        if (deviceCommandGuard.hasRunningLightCommand(raspberryDevice)) {
            log.debug("[AUTO_LIGHT] SKIP — 진행 중 조명 명령 존재 (userPlantId={})", userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_LIGHT,
                    TriggerSensorType.COMMAND_DUPLICATED,
                    triggerValue,
                    thresholdValue,
                    "이미 처리 대기 또는 처리 중인 조명 명령이 있어 자동 조명 제어를 건너뜁니다."
            );
            return false;
        }

        log.debug("[AUTO_LIGHT] cooldown 체크: 마지막 조명 명령 후 경과 시간 확인 (commandType={}, userPlantId={})",
                commandType, userPlant.getId());

        boolean recentlyLightOn = isRecentlyDeviceCommandCreated(
                raspberryDevice,
                CommandType.LIGHT_ON,
                cooldownMinutes
        );

        boolean recentlyLightOff = isRecentlyDeviceCommandCreated(
                raspberryDevice,
                CommandType.LIGHT_OFF,
                cooldownMinutes
        );

        if (recentlyLightOn || recentlyLightOff) {
            log.debug("[AUTO_LIGHT] SKIP — cooldown 미경과 (commandType={}, userPlantId={})",
                    commandType, userPlant.getId());
            saveSkipLog(
                    userPlant,
                    AutomationType.SKIP_LIGHT,
                    TriggerSensorType.COOLDOWN,
                    triggerValue,
                    thresholdValue,
                    "최근 조명 명령이 있어 쿨다운 시간 동안 자동 조명 제어를 건너뜁니다."
            );
            return false;
        }

        DeviceCommand command = DeviceCommand.createLightCommand(
                growSpace,
                userPlant,
                raspberryDevice,
                commandType
        );

        DeviceCommand savedCommand = deviceCommandRepository.save(command);

        log.info("[AUTO_LIGHT] {} 명령 생성 완료 (commandId={}, userPlantId={})",
                commandType, savedCommand.getId(), userPlant.getId());

        saveExecutedLog(
                userPlant,
                automationType,
                triggerSensorType,
                triggerValue,
                thresholdValue,
                savedCommand,
                successMessage
        );

        return true;
    }

    // 자동 급수 기준값 결정 — 학습 모델 우선, 없으면 설정값 사용
    private Double resolveWaterThreshold(
            UserPlant userPlant,
            AutomationSetting setting
    ) {
        Double fallbackThreshold = setting.getWaterThresholdPercent();

        if (fallbackThreshold == null) {
            fallbackThreshold = 35.0;
        }

        if (setting.getDecisionMode() == AutomationDecisionMode.RULE_BASED) {
            return fallbackThreshold;
        }

        AutomationModel model = findUsableLearningModel(userPlant, setting);

        if (model == null) {
            return fallbackThreshold;
        }

        if (model.getRecommendedWaterThresholdPercent() == null) {
            return fallbackThreshold;
        }

        return model.getRecommendedWaterThresholdPercent();
    }

    // resolve Watering Safety Threshold 처리
    private double resolveWateringSafetyThreshold(AutomationSetting setting) {
        Double waterThresholdPercent = setting.getWaterThresholdPercent();

        if (waterThresholdPercent == null) {
            waterThresholdPercent = 35.0;
        }

        return waterThresholdPercent + WATERING_SAFETY_MARGIN_PERCENT;
    }

    // 자동 LED ON 기준값 결정
    private Double resolveLightOnThreshold(
            UserPlant userPlant,
            AutomationSetting setting
    ) {
        Double fallbackThreshold = setting.getLightOnThresholdLux();

        if (fallbackThreshold == null) {
            fallbackThreshold = 300.0;
        }

        if (setting.getDecisionMode() == AutomationDecisionMode.RULE_BASED) {
            return fallbackThreshold;
        }

        AutomationModel model = findUsableLearningModel(userPlant, setting);

        if (model == null) {
            return fallbackThreshold;
        }

        if (model.getRecommendedLightOnThresholdLux() == null) {
            return fallbackThreshold;
        }

        return model.getRecommendedLightOnThresholdLux();
    }

    // 자동 LED OFF 기준값 결정
    private Double resolveLightOffThreshold(
            UserPlant userPlant,
            AutomationSetting setting
    ) {
        Double fallbackThreshold = setting.getLightOffThresholdLux();

        if (fallbackThreshold == null) {
            fallbackThreshold = 500.0;
        }

        if (setting.getDecisionMode() == AutomationDecisionMode.RULE_BASED) {
            return fallbackThreshold;
        }

        AutomationModel model = findUsableLearningModel(userPlant, setting);

        if (model == null) {
            return fallbackThreshold;
        }

        if (model.getRecommendedLightOffThresholdLux() == null) {
            return fallbackThreshold;
        }

        return model.getRecommendedLightOffThresholdLux();
    }

    // 자동화 판단용 최신 학습 모델 조회 — READY/신뢰도/데이터 수 조건 적용
    private AutomationModel findUsableLearningModel(
            UserPlant userPlant,
            AutomationSetting setting
    ) {
        if (setting.getDecisionMode() == null) {
            return null;
        }

        if (setting.getDecisionMode() == AutomationDecisionMode.RULE_BASED) {
            return null;
        }

        AutomationModel model =
                automationModelRepository
                        .findTopByUserPlantAndModelStatusAndDeletedFalseOrderByLastTrainedAtDesc(
                                userPlant,
                                AutomationModelStatus.READY
                        )
                        .orElse(null);

        if (model == null) {
            return null;
        }

        if (model.getConfidenceScore() == null
                || model.getConfidenceScore() < MODEL_CONFIDENCE_THRESHOLD) {
            return null;
        }

        int minLearningDataCount =
                setting.getMinLearningDataCount() == null
                        ? 30
                        : setting.getMinLearningDataCount();

        if (model.getSoilDataCount() == null
                || model.getSoilDataCount() < minLearningDataCount) {
            return null;
        }

        return model;
    }

    // 자동화 설정이 없으면 기본값으로 생성
    private AutomationSetting getOrCreateDefaultSetting(
            User user,
            UserPlant userPlant
    ) {
        return automationSettingRepository
                .findByUserPlantAndDeletedFalse(userPlant)
                .orElseGet(() -> automationSettingRepository.save(
                        AutomationSetting.createDefault(user, userPlant)
                ));
    }

    // 최근 N분 안에 해당 식물의 명령이 생성되었는지 확인
    private boolean isRecentlyCommandCreated(
            UserPlant userPlant,
            CommandType commandType,
            Integer cooldownMinutes
    ) {
        if (cooldownMinutes == null || cooldownMinutes <= 0) {
            return false;
        }

        return deviceCommandRepository
                .findTopByUserPlantAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
                        userPlant,
                        commandType
                )
                .map(command -> isWithinCooldown(command, cooldownMinutes))
                .orElse(false);
    }

    // 최근 N분 안에 해당 기기의 명령이 생성되었는지 확인 — 공간 공용 조명 판정용
    private boolean isRecentlyDeviceCommandCreated(
            IotDevice raspberryDevice,
            CommandType commandType,
            Integer cooldownMinutes
    ) {
        if (cooldownMinutes == null || cooldownMinutes <= 0) {
            return false;
        }

        return deviceCommandRepository
                .findTopByIotDeviceAndCommandTypeAndDeletedFalseOrderByRequestedAtDesc(
                        raspberryDevice,
                        commandType
                )
                .map(command -> isWithinCooldown(command, cooldownMinutes))
                .orElse(false);
    }

    // 명령 요청 시각이 쿨다운 구간 안인지 확인
    private boolean isWithinCooldown(
            DeviceCommand command,
            int cooldownMinutes
    ) {
        LocalDateTime requestedAt = command.getRequestedAt();

        if (requestedAt == null) {
            return false;
        }

        return requestedAt.isAfter(LocalDateTime.now().minusMinutes(cooldownMinutes));
    }

    // 조명 작동 시간대 확인 — 자정 넘김 범위 포함
    private boolean isTimeWithinRange(
            LocalTime now,
            LocalTime start,
            LocalTime end
    ) {
        if (start == null || end == null) {
            return true;
        }

        if (start.equals(end)) {
            return true;
        }

        if (start.isBefore(end)) {
            return !now.isBefore(start) && !now.isAfter(end);
        }

        return !now.isBefore(start) || !now.isAfter(end);
    }

    // save Executed Log 저장
    private void saveExecutedLog(
            UserPlant userPlant,
            AutomationType automationType,
            TriggerSensorType triggerSensorType,
            Double triggerValue,
            Double thresholdValue,
            DeviceCommand command,
            String message
    ) {
        automationLogRepository.save(
                AutomationLog.createExecutedLog(
                        userPlant,
                        automationType,
                        triggerSensorType,
                        triggerValue,
                        thresholdValue,
                        command,
                        message
                )
        );
    }

    // save Skip Log 저장
    private void saveSkipLog(
            UserPlant userPlant,
            AutomationType automationType,
            TriggerSensorType triggerSensorType,
            Double triggerValue,
            Double thresholdValue,
            String message
    ) {
        // 센서가 10분마다 들어오므로 같은 사유의 SKIP이 반복되면 로그가 의미 없이 쌓인다.
        // 직전 로그와 사유가 같으면 저장하지 않고, 사유가 바뀔 때만 남긴다.
        boolean sameAsLast = automationLogRepository
                .findTopByUserPlantAndAutomationTypeAndDeletedFalseOrderByIdDesc(userPlant, automationType)
                .filter(last -> last.getTriggerSensorType() == triggerSensorType
                        && java.util.Objects.equals(last.getMessage(), message))
                .isPresent();

        if (sameAsLast) {
            return;
        }

        automationLogRepository.save(
                AutomationLog.createSkippedLog(
                        userPlant,
                        automationType,
                        triggerSensorType,
                        triggerValue,
                        thresholdValue,
                        message
                )
        );
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    // find My User Plant 조회 — 없으면 예외 또는 Optional 반환
    private UserPlant findMyUserPlant(
            Long userPlantId,
            User user
    ) {
        return userPlantRepository.findByIdAndUserAndDeletedFalse(userPlantId, user)
                .orElseThrow(() -> new IllegalArgumentException("해당 식물을 찾을 수 없습니다."));
    }

    // validate Setting Request 검증
    private void validateSettingRequest(
            AutomationDto.UpdateSettingReqDto request
    ) {
        if (request == null) {
            throw new IllegalArgumentException("자동화 설정 요청이 비어 있습니다.");
        }

        if (request.getWaterThresholdPercent() != null) {
            if (request.getWaterThresholdPercent() < 0
                    || request.getWaterThresholdPercent() > 100) {
                throw new IllegalArgumentException("물 주기 기준값은 0~100 사이여야 합니다.");
            }
        }

        if (request.getWaterCooldownMinutes() != null) {
            if (request.getWaterCooldownMinutes() < 0) {
                throw new IllegalArgumentException("물 주기 쿨다운은 0 이상이어야 합니다.");
            }
        }

        if (request.getLightOnThresholdLux() != null) {
            if (request.getLightOnThresholdLux() < 0) {
                throw new IllegalArgumentException("LED ON 조도 기준은 0 이상이어야 합니다.");
            }
        }

        if (request.getLightOffThresholdLux() != null) {
            if (request.getLightOffThresholdLux() < 0) {
                throw new IllegalArgumentException("LED OFF 조도 기준은 0 이상이어야 합니다.");
            }
        }

        if (request.getLightOnThresholdLux() != null
                && request.getLightOffThresholdLux() != null) {
            if (request.getLightOnThresholdLux()
                    >= request.getLightOffThresholdLux()) {
                throw new IllegalArgumentException("LED OFF 기준 조도는 LED ON 기준 조도보다 커야 합니다.");
            }
        }

        if (request.getLightCooldownMinutes() != null) {
            if (request.getLightCooldownMinutes() < 0) {
                throw new IllegalArgumentException("조명 쿨다운은 0 이상이어야 합니다.");
            }
        }

        if (request.getMinLearningDataCount() != null) {
            if (request.getMinLearningDataCount() < 1) {
                throw new IllegalArgumentException("최소 학습 데이터 개수는 1 이상이어야 합니다.");
            }
        }
    }
}

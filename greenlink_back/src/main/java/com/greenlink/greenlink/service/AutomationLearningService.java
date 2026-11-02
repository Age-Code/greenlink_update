package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationModel;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AutomationDto;
import com.greenlink.greenlink.repository.AutomationModelRepository;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.EspSensorDataRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.RaspberrySensorDataRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

// 자동화 학습 서비스 — 최근 14일 통계로 임계치 산출
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AutomationLearningService {

    private static final int DEFAULT_TRAINING_DAYS = 14;

    private static final double MIN_WATER_THRESHOLD = 20.0;
    private static final double MAX_WATER_THRESHOLD = 45.0;

    private static final double MIN_LIGHT_ON_THRESHOLD = 50.0;
    private static final double MAX_LIGHT_ON_THRESHOLD = 800.0;

    private static final double MIN_LIGHT_OFF_THRESHOLD = 100.0;
    private static final double MAX_LIGHT_OFF_THRESHOLD = 1200.0;

    private static final double READY_CONFIDENCE_SCORE = 0.6;

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;

    private final AutomationSettingRepository automationSettingRepository;
    private final AutomationModelRepository automationModelRepository;

    private final EspSensorDataRepository espSensorDataRepository;
    private final RaspberrySensorDataRepository raspberrySensorDataRepository;
    private final DeviceCommandRepository deviceCommandRepository;
    private final GrowSpacePlantRepository growSpacePlantRepository;

    // 특정 식물의 최근 14일 데이터를 기반으로 자동화 모델 학습
    @Transactional
    public AutomationDto.ModelResDto trainUserPlantModel(
            Long userId,
            Long userPlantId
    ) {
        User user = findUser(userId);
        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        AutomationSetting setting = getOrCreateDefaultSetting(user, userPlant);

        LocalDateTime trainedTo = LocalDateTime.now();
        LocalDateTime trainedFrom = trainedTo.minusDays(DEFAULT_TRAINING_DAYS);

        List<EspSensorData> soilDataList =
                espSensorDataRepository.findByUserPlantAndMeasuredAtBetweenOrderByMeasuredAtAsc(
                        userPlant,
                        trainedFrom,
                        trainedTo
                );

        List<DeviceCommand> waterCommands =
                deviceCommandRepository.findByUserPlantAndCommandTypeAndRequestedAtBetweenAndDeletedFalseOrderByRequestedAtAsc(
                        userPlant,
                        CommandType.WATER,
                        trainedFrom,
                        trainedTo
                );

        GrowSpace growSpace = findGrowSpaceByUserPlant(userPlant);

        List<RaspberrySensorData> lightDataList = new ArrayList<>();

        if (growSpace != null) {
            lightDataList =
                    raspberrySensorDataRepository.findByGrowSpaceAndMeasuredAtBetweenOrderByMeasuredAtAsc(
                            growSpace,
                            trainedFrom,
                            trainedTo
                    );
        }

        int soilDataCount = soilDataList.size();
        int lightDataCount = lightDataList.size();
        int waterCommandCount = waterCommands.size();

        int minLearningDataCount =
                setting.getMinLearningDataCount() == null
                        ? 30
                        : setting.getMinLearningDataCount();

        if (soilDataCount < minLearningDataCount) {
            AutomationModel model = AutomationModel.createInsufficientDataModel(
                    userPlant,
                    soilDataCount,
                    lightDataCount,
                    waterCommandCount,
                    trainedFrom,
                    trainedTo
            );

            AutomationModel savedModel = automationModelRepository.save(model);

            return AutomationDto.ModelResDto.from(savedModel);
        }

        Double avgDryRatePerHour = calculateAverageDryRatePerHour(soilDataList);

        WaterLearningResult waterLearningResult =
                calculateWaterLearningResult(
                        userPlant,
                        waterCommands,
                        setting.getWaterThresholdPercent()
                );

        Double recommendedWaterThreshold =
                calculateRecommendedWaterThreshold(
                        waterLearningResult,
                        setting.getWaterThresholdPercent()
                );

        LightLearningResult lightLearningResult =
                calculateLightLearningResult(
                        lightDataList,
                        setting.getLightOnThresholdLux(),
                        setting.getLightOffThresholdLux()
                );

        Double confidenceScore =
                calculateConfidenceScore(
                        soilDataCount,
                        lightDataCount,
                        waterCommandCount,
                        waterLearningResult.getRecoverySampleCount()
                );

        AutomationModel model = AutomationModel.createReadyModel(
                userPlant,
                recommendedWaterThreshold,
                lightLearningResult.getRecommendedLightOnThresholdLux(),
                lightLearningResult.getRecommendedLightOffThresholdLux(),
                soilDataCount,
                lightDataCount,
                waterCommandCount,
                avgDryRatePerHour,
                waterLearningResult.getAvgWaterRecoveryPercent(),
                confidenceScore,
                trainedFrom,
                trainedTo
        );

        AutomationModel savedModel = automationModelRepository.save(model);

                // autoOptimizeEnabled = true이고, — confidenceScore가 충분하면 학습 결과를 실제 자동화 설정값에 반영한다.

        if (Boolean.TRUE.equals(setting.getAutoOptimizeEnabled())
                && confidenceScore >= READY_CONFIDENCE_SCORE) {
            setting.applyLearningThresholds(
                    savedModel.getRecommendedWaterThresholdPercent(),
                    savedModel.getRecommendedLightOnThresholdLux(),
                    savedModel.getRecommendedLightOffThresholdLux()
            );
        }

        return AutomationDto.ModelResDto.from(savedModel);
    }

    // 특정 식물의 최신 학습 모델 조회
    public AutomationDto.ModelResDto getLatestModel(
            Long userId,
            Long userPlantId
    ) {
        User user = findUser(userId);
        UserPlant userPlant = findMyUserPlant(userPlantId, user);

        AutomationModel model =
                automationModelRepository
                        .findTopByUserPlantAndDeletedFalseOrderByLastTrainedAtDesc(userPlant)
                        .orElseThrow(() -> new IllegalArgumentException("학습 모델이 아직 없습니다."));

        return AutomationDto.ModelResDto.from(model);
    }

    // 토양수분 감소 속도 계산
    private Double calculateAverageDryRatePerHour(
            List<EspSensorData> soilDataList
    ) {
        if (soilDataList == null || soilDataList.size() < 2) {
            return null;
        }

        List<Double> dryRates = new ArrayList<>();

        for (int i = 1; i < soilDataList.size(); i++) {
            EspSensorData prev = soilDataList.get(i - 1);
            EspSensorData curr = soilDataList.get(i);

            if (prev.getSoilMoisturePercent() == null
                    || curr.getSoilMoisturePercent() == null
                    || prev.getMeasuredAt() == null
                    || curr.getMeasuredAt() == null) {
                continue;
            }

            double prevPercent = prev.getSoilMoisturePercent();
            double currPercent = curr.getSoilMoisturePercent();

            if (currPercent >= prevPercent) {
                continue;
            }

            long minutes =
                    Duration.between(
                            prev.getMeasuredAt(),
                            curr.getMeasuredAt()
                    ).toMinutes();

            if (minutes <= 0 || minutes > 24 * 60) {
                continue;
            }

            double hours = minutes / 60.0;
            double dryRate = (prevPercent - currPercent) / hours;

            if (dryRate > 0 && dryRate <= 20) {
                dryRates.add(dryRate);
            }
        }

        if (dryRates.isEmpty()) {
            return null;
        }

        return average(dryRates);
    }

    // 물 주기 전후 토양수분 회복량 계산
    private WaterLearningResult calculateWaterLearningResult(
            UserPlant userPlant,
            List<DeviceCommand> waterCommands,
            Double fallbackWaterThreshold
    ) {
        if (waterCommands == null || waterCommands.isEmpty()) {
            return new WaterLearningResult(
                    fallbackWaterThreshold,
                    null,
                    0
            );
        }

        List<Double> beforeWaterPercents = new ArrayList<>();
        List<Double> recoveryPercents = new ArrayList<>();

        for (DeviceCommand command : waterCommands) {
            if (command.getRequestedAt() == null) {
                continue;
            }

            LocalDateTime waterTime = command.getRequestedAt();

            EspSensorData beforeData =
                    espSensorDataRepository
                            .findTopByUserPlantAndMeasuredAtLessThanEqualOrderByMeasuredAtDesc(
                                    userPlant,
                                    waterTime
                            )
                            .orElse(null);

            EspSensorData afterData =
                    espSensorDataRepository
                            .findTopByUserPlantAndMeasuredAtGreaterThanEqualOrderByMeasuredAtAsc(
                                    userPlant,
                                    waterTime.plusMinutes(30)
                            )
                            .orElse(null);

            if (beforeData == null || afterData == null) {
                continue;
            }

            if (beforeData.getSoilMoisturePercent() == null
                    || afterData.getSoilMoisturePercent() == null) {
                continue;
            }

            double beforePercent = beforeData.getSoilMoisturePercent();
            double afterPercent = afterData.getSoilMoisturePercent();

            double recovery = afterPercent - beforePercent;

            beforeWaterPercents.add(beforePercent);

            if (recovery > 0 && recovery <= 80) {
                recoveryPercents.add(recovery);
            }
        }

        Double avgBeforeWaterPercent =
                beforeWaterPercents.isEmpty()
                        ? fallbackWaterThreshold
                        : average(beforeWaterPercents);

        Double avgRecoveryPercent =
                recoveryPercents.isEmpty()
                        ? null
                        : average(recoveryPercents);

        return new WaterLearningResult(
                avgBeforeWaterPercent,
                avgRecoveryPercent,
                recoveryPercents.size()
        );
    }

    // 추천 급수 기준값 계산 — 급수 직전 평균 수분 기준
    private Double calculateRecommendedWaterThreshold(
            WaterLearningResult waterLearningResult,
            Double fallbackWaterThreshold
    ) {
        if (waterLearningResult == null
                || waterLearningResult.getAvgBeforeWaterPercent() == null) {
            return fallbackWaterThreshold;
        }

        double calculated =
                waterLearningResult.getAvgBeforeWaterPercent() + 2.0;

        return clamp(
                calculated,
                MIN_WATER_THRESHOLD,
                MAX_WATER_THRESHOLD
        );
    }

    // 조도 데이터 기반 LED 기준값 계산 — 단순 통계 방식
    private LightLearningResult calculateLightLearningResult(
            List<RaspberrySensorData> lightDataList,
            Double fallbackLightOnThreshold,
            Double fallbackLightOffThreshold
    ) {
        if (lightDataList == null || lightDataList.size() < 10) {
            return new LightLearningResult(
                    fallbackLightOnThreshold,
                    fallbackLightOffThreshold
            );
        }

        List<Double> lightValues =
                lightDataList.stream()
                        .map(RaspberrySensorData::getLight)
                        .filter(value -> value != null && value >= 0)
                        .sorted()
                        .toList();

        if (lightValues.size() < 10) {
            return new LightLearningResult(
                    fallbackLightOnThreshold,
                    fallbackLightOffThreshold
            );
        }

        double p25 = percentile(lightValues, 0.25);
        double p75 = percentile(lightValues, 0.75);

        double recommendedOn =
                clamp(
                        p25,
                        MIN_LIGHT_ON_THRESHOLD,
                        MAX_LIGHT_ON_THRESHOLD
                );

        double recommendedOff =
                clamp(
                        p75,
                        MIN_LIGHT_OFF_THRESHOLD,
                        MAX_LIGHT_OFF_THRESHOLD
                );

        if (recommendedOff <= recommendedOn) {
            recommendedOff = recommendedOn + 200.0;
        }

        return new LightLearningResult(
                recommendedOn,
                recommendedOff
        );
    }

    // 모델 신뢰도 계산 — 0.0 ~ 1.0 사이 값
    private Double calculateConfidenceScore(
            int soilDataCount,
            int lightDataCount,
            int waterCommandCount,
            int recoverySampleCount
    ) {
        double soilScore = Math.min(soilDataCount / 100.0, 1.0) * 0.45;
        double lightScore = Math.min(lightDataCount / 100.0, 1.0) * 0.20;
        double waterCommandScore = Math.min(waterCommandCount / 10.0, 1.0) * 0.25;
        double recoveryScore = Math.min(recoverySampleCount / 10.0, 1.0) * 0.10;

        return clamp(
                soilScore + lightScore + waterCommandScore + recoveryScore,
                0.0,
                1.0
        );
    }

    // find Grow Space By User Plant 조회 — 없으면 예외 또는 Optional 반환
    private GrowSpace findGrowSpaceByUserPlant(UserPlant userPlant) {
        GrowSpacePlant growSpacePlant =
                growSpacePlantRepository
                        .findTopByUserPlantAndActiveTrueAndDeletedFalse(userPlant)
                        .orElse(null);

        if (growSpacePlant == null) {
            return null;
        }

        return growSpacePlant.getGrowSpace();
    }

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

    // find User 조회 — 없으면 예외 또는 Optional 반환
    private User findUser(Long userId) {
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

    // 평균값 계산
    private Double average(List<Double> values) {
        if (values == null || values.isEmpty()) {
            return null;
        }

        return values.stream()
                .mapToDouble(Double::doubleValue)
                .average()
                .orElse(0.0);
    }

    // percentile 계산
    private double percentile(
            List<Double> sortedValues,
            double percentile
    ) {
        if (sortedValues == null || sortedValues.isEmpty()) {
            return 0.0;
        }

        List<Double> values =
                sortedValues.stream()
                        .sorted(Comparator.naturalOrder())
                        .toList();

        int index =
                (int) Math.floor((values.size() - 1) * percentile);

        return values.get(index);
    }

    // 값 범위 제한
    private double clamp(
            double value,
            double min,
            double max
    ) {
        return Math.max(min, Math.min(max, value));
    }

    // WaterLearningResult DTO — API 요청/응답 데이터
    private static class WaterLearningResult {

        private final Double avgBeforeWaterPercent;

        private final Double avgWaterRecoveryPercent;

        private final int recoverySampleCount;

        // WaterLearningResult 생성
        public WaterLearningResult(
                Double avgBeforeWaterPercent,
                Double avgWaterRecoveryPercent,
                int recoverySampleCount
        ) {
            this.avgBeforeWaterPercent = avgBeforeWaterPercent;
            this.avgWaterRecoveryPercent = avgWaterRecoveryPercent;
            this.recoverySampleCount = recoverySampleCount;
        }

        public Double getAvgBeforeWaterPercent() {
            return avgBeforeWaterPercent;
        }

        public Double getAvgWaterRecoveryPercent() {
            return avgWaterRecoveryPercent;
        }

        public int getRecoverySampleCount() {
            return recoverySampleCount;
        }
    }

    // LightLearningResult DTO — API 요청/응답 데이터
    private static class LightLearningResult {

        private final Double recommendedLightOnThresholdLux;

        private final Double recommendedLightOffThresholdLux;

        // LightLearningResult 생성
        public LightLearningResult(
                Double recommendedLightOnThresholdLux,
                Double recommendedLightOffThresholdLux
        ) {
            this.recommendedLightOnThresholdLux = recommendedLightOnThresholdLux;
            this.recommendedLightOffThresholdLux = recommendedLightOffThresholdLux;
        }

        public Double getRecommendedLightOnThresholdLux() {
            return recommendedLightOnThresholdLux;
        }

        public Double getRecommendedLightOffThresholdLux() {
            return recommendedLightOffThresholdLux;
        }
    }
}

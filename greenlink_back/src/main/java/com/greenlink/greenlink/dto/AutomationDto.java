package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.automation.AutomationDecisionMode;
import com.greenlink.greenlink.domain.automation.AutomationLog;
import com.greenlink.greenlink.domain.automation.AutomationModel;
import com.greenlink.greenlink.domain.automation.AutomationModelStatus;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.automation.AutomationType;
import com.greenlink.greenlink.domain.automation.TriggerSensorType;
import lombok.*;

import java.time.LocalDateTime;
import java.time.LocalTime;

// AutomationDto — API 요청/응답 DTO
public class AutomationDto {

    // 자동화 설정 조회 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SettingResDto {

        private Long automationSettingId;

        private Long userPlantId;

        private Boolean autoWaterEnabled;

        private Boolean autoLightEnabled;

        // 학습 기반 자동 최적화 사용 여부
        private Boolean autoOptimizeEnabled;

        private boolean wateringSafetyEnabled;

        // 자동화 판단 방식 — RULE_BASED / LEARNING_BASED / HYBRID
        private AutomationDecisionMode decisionMode;

        // 학습 모델을 사용하기 위한 최소 센서 데이터 개수
        private Integer minLearningDataCount;

        private Double waterThresholdPercent;

        private Integer waterCooldownMinutes;

        private Double lightOnThresholdLux;

        private Double lightOffThresholdLux;

        private LocalTime lightStartTime;

        private LocalTime lightEndTime;

        private Integer lightCooldownMinutes;

        private LocalDateTime createdAt;

        private LocalDateTime modifiedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static SettingResDto from(AutomationSetting setting) {
            return SettingResDto.builder()
                    .automationSettingId(setting.getId())
                    .userPlantId(setting.getUserPlant().getId())
                    .autoWaterEnabled(setting.getAutoWaterEnabled())
                    .autoLightEnabled(setting.getAutoLightEnabled())
                    .autoOptimizeEnabled(setting.getAutoOptimizeEnabled())
                    .wateringSafetyEnabled(setting.isWateringSafetyEnabled())
                    .decisionMode(setting.getDecisionMode())
                    .minLearningDataCount(setting.getMinLearningDataCount())
                    .waterThresholdPercent(setting.getWaterThresholdPercent())
                    .waterCooldownMinutes(setting.getWaterCooldownMinutes())
                    .lightOnThresholdLux(setting.getLightOnThresholdLux())
                    .lightOffThresholdLux(setting.getLightOffThresholdLux())
                    .lightStartTime(setting.getLightStartTime())
                    .lightEndTime(setting.getLightEndTime())
                    .lightCooldownMinutes(setting.getLightCooldownMinutes())
                    .createdAt(setting.getCreatedAt())
                    .modifiedAt(setting.getModifiedAt())
                    .build();
        }
    }

    // 자동화 설정 수정 요청 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateSettingReqDto {

        private Boolean autoWaterEnabled;

        private Boolean autoLightEnabled;

        // 학습 기반 자동 최적화 사용 여부
        private Boolean autoOptimizeEnabled;

        private Boolean wateringSafetyEnabled;

        // 자동화 판단 방식 — RULE_BASED / LEARNING_BASED / HYBRID
        private AutomationDecisionMode decisionMode;

        // 학습 모델을 사용하기 위한 최소 센서 데이터 개수
        private Integer minLearningDataCount;

        private Double waterThresholdPercent;

        private Integer waterCooldownMinutes;

        private Double lightOnThresholdLux;

        private Double lightOffThresholdLux;

        private LocalTime lightStartTime;

        private LocalTime lightEndTime;

        private Integer lightCooldownMinutes;
    }

    // 자동화 로그 조회 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LogResDto {

        private Long automationLogId;

        private Long userPlantId;

        private AutomationType automationType;

        private TriggerSensorType triggerSensorType;

        private Double triggerValue;

        private Double thresholdValue;

        private Long commandId;

        private String message;

        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static LogResDto from(AutomationLog log) {
            return LogResDto.builder()
                    .automationLogId(log.getId())
                    .userPlantId(log.getUserPlant().getId())
                    .automationType(log.getAutomationType())
                    .triggerSensorType(log.getTriggerSensorType())
                    .triggerValue(log.getTriggerValue())
                    .thresholdValue(log.getThresholdValue())
                    .commandId(
                            log.getCommand() == null
                                    ? null
                                    : log.getCommand().getId()
                    )
                    .message(log.getMessage())
                    .createdAt(log.getCreatedAt())
                    .build();
        }
    }

    // 학습 모델 조회 응답 DTO — 이후 학습 결과 조회 API에서 사용한다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ModelResDto {

        private Long automationModelId;

        private Long userPlantId;

        private Double recommendedWaterThresholdPercent;

        private Double recommendedLightOnThresholdLux;

        private Double recommendedLightOffThresholdLux;

        private Integer soilDataCount;

        private Integer lightDataCount;

        private Integer waterCommandCount;

        private Double avgDryRatePerHour;

        private Double avgWaterRecoveryPercent;

        private Double confidenceScore;

        private AutomationModelStatus modelStatus;

        private LocalDateTime trainedFrom;

        private LocalDateTime trainedTo;

        private LocalDateTime lastTrainedAt;

        private LocalDateTime createdAt;

        private LocalDateTime modifiedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static ModelResDto from(AutomationModel model) {
            return ModelResDto.builder()
                    .automationModelId(model.getId())
                    .userPlantId(model.getUserPlant().getId())
                    .recommendedWaterThresholdPercent(model.getRecommendedWaterThresholdPercent())
                    .recommendedLightOnThresholdLux(model.getRecommendedLightOnThresholdLux())
                    .recommendedLightOffThresholdLux(model.getRecommendedLightOffThresholdLux())
                    .soilDataCount(model.getSoilDataCount())
                    .lightDataCount(model.getLightDataCount())
                    .waterCommandCount(model.getWaterCommandCount())
                    .avgDryRatePerHour(model.getAvgDryRatePerHour())
                    .avgWaterRecoveryPercent(model.getAvgWaterRecoveryPercent())
                    .confidenceScore(model.getConfidenceScore())
                    .modelStatus(model.getModelStatus())
                    .trainedFrom(model.getTrainedFrom())
                    .trainedTo(model.getTrainedTo())
                    .lastTrainedAt(model.getLastTrainedAt())
                    .createdAt(model.getCreatedAt())
                    .modifiedAt(model.getModifiedAt())
                    .build();
        }
    }
}

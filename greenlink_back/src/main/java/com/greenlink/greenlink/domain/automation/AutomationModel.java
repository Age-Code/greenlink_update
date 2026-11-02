package com.greenlink.greenlink.domain.automation;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// AutomationModel — 도메인 모델
@Entity
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Table(name = "automation_model")
public class AutomationModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 학습 대상 식물
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 학습된 추천 자동 급수 기준값
    @Column(name = "recommended_water_threshold_percent")
    private Double recommendedWaterThresholdPercent;

    // 학습된 추천 LED ON 기준값
    @Column(name = "recommended_light_on_threshold_lux")
    private Double recommendedLightOnThresholdLux;

    // 학습된 추천 LED OFF 기준값
    @Column(name = "recommended_light_off_threshold_lux")
    private Double recommendedLightOffThresholdLux;

    // 학습에 사용된 토양수분 데이터 개수
    @Column(name = "soil_data_count")
    private Integer soilDataCount;

    // 학습에 사용된 조도 데이터 개수
    @Column(name = "light_data_count")
    private Integer lightDataCount;

    // 학습에 사용된 급수 명령 개수
    @Column(name = "water_command_count")
    private Integer waterCommandCount;

    // 시간당 평균 토양수분 감소량
    @Column(name = "avg_dry_rate_per_hour")
    private Double avgDryRatePerHour;

    // 물 주기 후 평균 토양수분 회복량
    @Column(name = "avg_water_recovery_percent")
    private Double avgWaterRecoveryPercent;

    // 모델 신뢰도 — 0.0 ~ 1.0 사이 값
    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Enumerated(EnumType.STRING)
    @Column(name = "model_status", nullable = false)
    private AutomationModelStatus modelStatus;

    // 학습에 사용한 데이터 시작 시점
    @Column(name = "trained_from")
    private LocalDateTime trainedFrom;

    // 학습에 사용한 데이터 종료 시점
    @Column(name = "trained_to")
    private LocalDateTime trainedTo;

    // 마지막 학습 시각
    @Column(name = "last_trained_at")
    private LocalDateTime lastTrainedAt;

    @Column(nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // 생성 시각 초기화
    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();

        if (createdAt == null) {
            createdAt = now;
        }

        if (modifiedAt == null) {
            modifiedAt = now;
        }

        if (lastTrainedAt == null) {
            lastTrainedAt = now;
        }

        if (deleted == null) {
            deleted = false;
        }

        if (modelStatus == null) {
            modelStatus = AutomationModelStatus.INSUFFICIENT_DATA;
        }
    }

    // 수정 시각 갱신
    @PreUpdate
    protected void onUpdate() {
        modifiedAt = LocalDateTime.now();
    }

    // create Ready Model 생성
    public static AutomationModel createReadyModel(
            UserPlant userPlant,
            Double recommendedWaterThresholdPercent,
            Double recommendedLightOnThresholdLux,
            Double recommendedLightOffThresholdLux,
            Integer soilDataCount,
            Integer lightDataCount,
            Integer waterCommandCount,
            Double avgDryRatePerHour,
            Double avgWaterRecoveryPercent,
            Double confidenceScore,
            LocalDateTime trainedFrom,
            LocalDateTime trainedTo
    ) {
        return AutomationModel.builder()
                .userPlant(userPlant)
                .recommendedWaterThresholdPercent(recommendedWaterThresholdPercent)
                .recommendedLightOnThresholdLux(recommendedLightOnThresholdLux)
                .recommendedLightOffThresholdLux(recommendedLightOffThresholdLux)
                .soilDataCount(soilDataCount)
                .lightDataCount(lightDataCount)
                .waterCommandCount(waterCommandCount)
                .avgDryRatePerHour(avgDryRatePerHour)
                .avgWaterRecoveryPercent(avgWaterRecoveryPercent)
                .confidenceScore(confidenceScore)
                .modelStatus(AutomationModelStatus.READY)
                .trainedFrom(trainedFrom)
                .trainedTo(trainedTo)
                .lastTrainedAt(LocalDateTime.now())
                .deleted(false)
                .build();
    }

    // create Insufficient Data Model 생성
    public static AutomationModel createInsufficientDataModel(
            UserPlant userPlant,
            Integer soilDataCount,
            Integer lightDataCount,
            Integer waterCommandCount,
            LocalDateTime trainedFrom,
            LocalDateTime trainedTo
    ) {
        return AutomationModel.builder()
                .userPlant(userPlant)
                .soilDataCount(soilDataCount)
                .lightDataCount(lightDataCount)
                .waterCommandCount(waterCommandCount)
                .confidenceScore(0.0)
                .modelStatus(AutomationModelStatus.INSUFFICIENT_DATA)
                .trainedFrom(trainedFrom)
                .trainedTo(trainedTo)
                .lastTrainedAt(LocalDateTime.now())
                .deleted(false)
                .build();
    }

    // create Failed Model 생성
    public static AutomationModel createFailedModel(
            UserPlant userPlant,
            String reason,
            LocalDateTime trainedFrom,
            LocalDateTime trainedTo
    ) {
        return AutomationModel.builder()
                .userPlant(userPlant)
                .confidenceScore(0.0)
                .modelStatus(AutomationModelStatus.FAILED)
                .trainedFrom(trainedFrom)
                .trainedTo(trainedTo)
                .lastTrainedAt(LocalDateTime.now())
                .deleted(false)
                .build();
    }

    // soft delete 처리
    public void softDelete() {
        this.deleted = true;
    }
}

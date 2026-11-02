package com.greenlink.greenlink.domain.automation;

import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Table(
        name = "automation_setting",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_automation_setting_user_plant",
                        columnNames = "user_plant_id"
                )
        }
)
// AutomationSetting — 도메인 모델
public class AutomationSetting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 자동화 설정 소유 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 자동화 설정 대상 식물
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 자동 물 주기 사용 여부
    @Column(name = "auto_water_enabled", nullable = false)
    @Builder.Default
    private Boolean autoWaterEnabled = false;

    // 자동 조명 사용 여부
    @Column(name = "auto_light_enabled", nullable = false)
    @Builder.Default
    private Boolean autoLightEnabled = false;

    // 학습 기반 자동 최적화 사용 여부
    @Column(name = "auto_optimize_enabled", nullable = false)
    @Builder.Default
    private Boolean autoOptimizeEnabled = false;

    // 과습 안전 모드 사용 여부
    @Column(name = "watering_safety_enabled", nullable = false)
    @Builder.Default
    private boolean wateringSafetyEnabled = false;

    // 자동화 판단 방식
    @Enumerated(EnumType.STRING)
    @Column(name = "decision_mode", nullable = false)
    @Builder.Default
    private AutomationDecisionMode decisionMode = AutomationDecisionMode.HYBRID;

    // 학습 모델을 사용하기 위한 최소 센서 데이터 개수
    @Column(name = "min_learning_data_count", nullable = false)
    @Builder.Default
    private Integer minLearningDataCount = 30;

    // 자동 급수 기준 토양수분 퍼센트
    @Column(name = "water_threshold_percent", nullable = false)
    @Builder.Default
    private Double waterThresholdPercent = 35.0;

    // 자동 급수 쿨다운 시간 — 단위: 분
    @Column(name = "water_cooldown_minutes", nullable = false)
    @Builder.Default
    private Integer waterCooldownMinutes = 30;

    // LED ON 기준 조도
    @Column(name = "light_on_threshold_lux", nullable = false)
    @Builder.Default
    private Double lightOnThresholdLux = 300.0;

    // LED OFF 기준 조도
    @Column(name = "light_off_threshold_lux", nullable = false)
    @Builder.Default
    private Double lightOffThresholdLux = 500.0;

    // 자동 조명 시작 시간
    @Column(name = "light_start_time", nullable = false)
    @Builder.Default
    private LocalTime lightStartTime = LocalTime.of(8, 0);

    // 자동 조명 종료 시간
    @Column(name = "light_end_time", nullable = false)
    @Builder.Default
    private LocalTime lightEndTime = LocalTime.of(18, 0);

    // 자동 조명 쿨다운 시간 — 단위: 분
    @Column(name = "light_cooldown_minutes", nullable = false)
    @Builder.Default
    private Integer lightCooldownMinutes = 10;

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

        if (deleted == null) {
            deleted = false;
        }

        if (autoWaterEnabled == null) {
            autoWaterEnabled = false;
        }

        if (autoLightEnabled == null) {
            autoLightEnabled = false;
        }

        if (autoOptimizeEnabled == null) {
            autoOptimizeEnabled = false;
        }

        if (decisionMode == null) {
            decisionMode = AutomationDecisionMode.HYBRID;
        }

        if (minLearningDataCount == null) {
            minLearningDataCount = 30;
        }

        if (waterThresholdPercent == null) {
            waterThresholdPercent = 35.0;
        }

        if (waterCooldownMinutes == null) {
            waterCooldownMinutes = 30;
        }

        if (lightOnThresholdLux == null) {
            lightOnThresholdLux = 300.0;
        }

        if (lightOffThresholdLux == null) {
            lightOffThresholdLux = 500.0;
        }

        if (lightStartTime == null) {
            lightStartTime = LocalTime.of(8, 0);
        }

        if (lightEndTime == null) {
            lightEndTime = LocalTime.of(18, 0);
        }

        if (lightCooldownMinutes == null) {
            lightCooldownMinutes = 10;
        }
    }

    // 수정 시각 갱신
    @PreUpdate
    protected void onUpdate() {
        modifiedAt = LocalDateTime.now();
    }

    // 자동화 설정 수정 — null로 들어온 값은 기존 값을 유지한다.
    public void updateSetting(
            Boolean autoWaterEnabled,
            Boolean autoLightEnabled,
            Double waterThresholdPercent,
            Integer waterCooldownMinutes,
            Double lightOnThresholdLux,
            Double lightOffThresholdLux,
            LocalTime lightStartTime,
            LocalTime lightEndTime,
            Integer lightCooldownMinutes,
            Boolean autoOptimizeEnabled,
            AutomationDecisionMode decisionMode,
            Integer minLearningDataCount
    ) {
        if (autoWaterEnabled != null) {
            this.autoWaterEnabled = autoWaterEnabled;
        }

        if (autoLightEnabled != null) {
            this.autoLightEnabled = autoLightEnabled;
        }

        if (waterThresholdPercent != null) {
            this.waterThresholdPercent = waterThresholdPercent;
        }

        if (waterCooldownMinutes != null) {
            this.waterCooldownMinutes = waterCooldownMinutes;
        }

        if (lightOnThresholdLux != null) {
            this.lightOnThresholdLux = lightOnThresholdLux;
        }

        if (lightOffThresholdLux != null) {
            this.lightOffThresholdLux = lightOffThresholdLux;
        }

        if (lightStartTime != null) {
            this.lightStartTime = lightStartTime;
        }

        if (lightEndTime != null) {
            this.lightEndTime = lightEndTime;
        }

        if (lightCooldownMinutes != null) {
            this.lightCooldownMinutes = lightCooldownMinutes;
        }

        if (autoOptimizeEnabled != null) {
            this.autoOptimizeEnabled = autoOptimizeEnabled;
        }

        if (decisionMode != null) {
            this.decisionMode = decisionMode;
        }

        if (minLearningDataCount != null) {
            this.minLearningDataCount = minLearningDataCount;
        }
    }

    // update Watering Safety Enabled 수정
    public void updateWateringSafetyEnabled(boolean enabled) {
        this.wateringSafetyEnabled = enabled;
    }

    // 학습 결과를 자동 설정값에 반영 — 학습 모델의 추천값을 automation_setting에 실제 적용할 때 사용한다.
    public void applyLearningThresholds(
            Double recommendedWaterThresholdPercent,
            Double recommendedLightOnThresholdLux,
            Double recommendedLightOffThresholdLux
    ) {
        if (recommendedWaterThresholdPercent != null) {
            this.waterThresholdPercent = recommendedWaterThresholdPercent;
        }

        if (recommendedLightOnThresholdLux != null) {
            this.lightOnThresholdLux = recommendedLightOnThresholdLux;
        }

        if (recommendedLightOffThresholdLux != null) {
            this.lightOffThresholdLux = recommendedLightOffThresholdLux;
        }
    }

    // create Default 생성
    public static AutomationSetting createDefault(
            User user,
            UserPlant userPlant
    ) {
        return AutomationSetting.builder()
                .user(user)
                .userPlant(userPlant)
                .autoWaterEnabled(false)
                .autoLightEnabled(false)
                .autoOptimizeEnabled(false)
                .wateringSafetyEnabled(false)
                .decisionMode(AutomationDecisionMode.HYBRID)
                .minLearningDataCount(30)
                .waterThresholdPercent(35.0)
                .waterCooldownMinutes(30)
                .lightOnThresholdLux(300.0)
                .lightOffThresholdLux(500.0)
                .lightStartTime(LocalTime.of(8, 0))
                .lightEndTime(LocalTime.of(18, 0))
                .lightCooldownMinutes(10)
                .deleted(false)
                .build();
    }

    // soft delete 처리
    public void softDelete() {
        this.deleted = true;
    }
}

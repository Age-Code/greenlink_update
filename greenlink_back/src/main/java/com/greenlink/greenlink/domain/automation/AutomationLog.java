package com.greenlink.greenlink.domain.automation;

import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// AutomationLog — 도메인 모델
@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "automation_log")
public class AutomationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 자동화 판단 대상 식물
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 자동화 판단/실행 유형
    @Enumerated(EnumType.STRING)
    @Column(name = "automation_type", nullable = false, length = 50)
    private AutomationType automationType;

    // 자동화 판단 근거 센서/조건
    @Enumerated(EnumType.STRING)
    @Column(name = "trigger_sensor_type", nullable = false, length = 50)
    private TriggerSensorType triggerSensorType;

    // 자동화 판단에 사용된 실제 값
    @Column(name = "trigger_value")
    private Double triggerValue;

    // 자동화 판단 기준값
    @Column(name = "threshold_value")
    private Double thresholdValue;

    // 자동화로 생성된 명령 — 자동화가 실제 명령을 생성하지 않고 스킵된 경우 null일 수 있다.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "command_id")
    private DeviceCommand command;

    // 자동화 판단 결과 메시지
    @Column(name = "message", length = 500)
    private String message;

    // 소프트 삭제 여부
    @Builder.Default
    @Column(nullable = false)
    private Boolean deleted = false;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // 생성 시각 초기화
    @PrePersist
    public void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }

        if (deleted == null) {
            deleted = false;
        }
    }

    // 자동화 실행 로그 생성
    public static AutomationLog createExecutedLog(
            UserPlant userPlant,
            AutomationType automationType,
            TriggerSensorType triggerSensorType,
            Double triggerValue,
            Double thresholdValue,
            DeviceCommand command,
            String message
    ) {
        return AutomationLog.builder()
                .userPlant(userPlant)
                .automationType(automationType)
                .triggerSensorType(triggerSensorType)
                .triggerValue(triggerValue)
                .thresholdValue(thresholdValue)
                .command(command)
                .message(message)
                .deleted(false)
                .build();
    }

    // 자동화 스킵 로그 생성
    public static AutomationLog createSkippedLog(
            UserPlant userPlant,
            AutomationType automationType,
            TriggerSensorType triggerSensorType,
            Double triggerValue,
            Double thresholdValue,
            String message
    ) {
        return AutomationLog.builder()
                .userPlant(userPlant)
                .automationType(automationType)
                .triggerSensorType(triggerSensorType)
                .triggerValue(triggerValue)
                .thresholdValue(thresholdValue)
                .command(null)
                .message(message)
                .deleted(false)
                .build();
    }

    // soft delete 처리
    public void softDelete() {
        this.deleted = true;
    }
}

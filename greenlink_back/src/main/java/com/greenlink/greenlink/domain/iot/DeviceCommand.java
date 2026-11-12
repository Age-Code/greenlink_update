package com.greenlink.greenlink.domain.iot;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// DeviceCommand — 도메인 모델
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "device_command")
public class DeviceCommand {

    private static final int DEFAULT_WATER_DURATION_SECONDS = 10;
    public static final int MAX_WATER_DURATION_SECONDS = 10;

    // 라즈베리파이가 응답하지 않는 명령을 방치 상태로 판정하는 기준 시간
    public static final int STALE_COMMAND_TIMEOUT_MINUTES = 5;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 명령이 발생한 재배 공간
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id", nullable = false)
    private GrowSpace growSpace;

    // 명령 대상 식물
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 명령을 처리할 라즈베리파이
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "iot_device_id", nullable = false)
    private IotDevice iotDevice;

    // WATER 명령일 때 사용할 펌프 채널
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pump_channel_id")
    private PumpChannel pumpChannel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private CommandType commandType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private CommandStatus commandStatus;

    // 실제 라즈베리파이가 펌프를 작동시킬 시간 — 현재 MVP에서는 서버 고정값 10초를 사용한다.
    private Integer durationSeconds;

    @Column(nullable = false)
    private LocalDateTime requestedAt;

    private LocalDateTime processedAt;

    private LocalDateTime completedAt;

    @Column(length = 500)
    private String resultMessage;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // DeviceCommand 생성
    @Builder
    private DeviceCommand(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice iotDevice,
            PumpChannel pumpChannel,
            CommandType commandType,
            Integer durationSeconds
    ) {
        if (!iotDevice.isRaspberryPi()) {
            throw new IllegalStateException("명령은 라즈베리파이 기기로만 전달할 수 있습니다.");
        }

        validateWaterDuration(commandType, durationSeconds);

        this.growSpace = growSpace;
        this.userPlant = userPlant;
        this.iotDevice = iotDevice;
        this.pumpChannel = pumpChannel;
        this.commandType = commandType;
        this.commandStatus = CommandStatus.PENDING;
        this.durationSeconds = durationSeconds;
        this.requestedAt = LocalDateTime.now();
        this.deleted = false;
    }

    private static void validateWaterDuration(
            CommandType commandType,
            Integer durationSeconds
    ) {
        if (commandType != CommandType.WATER) {
            return;
        }

        if (durationSeconds == null
                || durationSeconds <= 0
                || durationSeconds > MAX_WATER_DURATION_SECONDS) {
            throw new IllegalArgumentException(
                    "급수 시간은 0초보다 크고 "
                            + MAX_WATER_DURATION_SECONDS
                            + "초 이하여야 합니다."
            );
        }
    }

    // 급수 명령 생성 — 기본 급수 시간 10초
    public static DeviceCommand createWaterCommand(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice raspberryDevice,
            PumpChannel pumpChannel
    ) {
        return DeviceCommand.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .iotDevice(raspberryDevice)
                .pumpChannel(pumpChannel)
                .commandType(CommandType.WATER)
                .durationSeconds(DEFAULT_WATER_DURATION_SECONDS)
                .build();
    }

    // 조명 명령 생성 — LIGHT_ON/LIGHT_OFF 검증
    public static DeviceCommand createLightCommand(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice raspberryDevice,
            CommandType commandType
    ) {
        if (commandType != CommandType.LIGHT_ON &&
                commandType != CommandType.LIGHT_OFF) {
            throw new IllegalArgumentException("조명 명령 타입이 아닙니다.");
        }

        return DeviceCommand.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .iotDevice(raspberryDevice)
                .pumpChannel(null)
                .commandType(commandType)
                .durationSeconds(null)
                .build();
    }

    // 센서 새로고침 명령 생성 — duration 없음
    public static DeviceCommand createSensorRefreshCommand(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice raspberryDevice
    ) {
        return DeviceCommand.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .iotDevice(raspberryDevice)
                .pumpChannel(null)
                .commandType(CommandType.SENSOR_REFRESH)
                .durationSeconds(null)
                .build();
    }

    // 명령 처리 시작 표시
    public void markProcessing() {
        if (this.commandStatus != CommandStatus.PENDING) {
            throw new IllegalStateException("대기 중인 명령만 처리 시작할 수 있습니다.");
        }

        this.commandStatus = CommandStatus.PROCESSING;
        this.processedAt = LocalDateTime.now();
    }

    // 명령 성공 완료 처리
    public void completeSuccess(String resultMessage) {
        if (this.commandStatus != CommandStatus.PROCESSING) {
            throw new IllegalStateException("처리 중인 명령만 완료 처리할 수 있습니다.");
        }

        this.commandStatus = CommandStatus.SUCCESS;
        this.completedAt = LocalDateTime.now();
        this.resultMessage = resultMessage;
    }

    // 명령 실패 완료 처리
    public void completeFailed(String resultMessage) {
        if (this.commandStatus != CommandStatus.PROCESSING) {
            throw new IllegalStateException("처리 중인 명령만 실패 처리할 수 있습니다.");
        }

        this.commandStatus = CommandStatus.FAILED;
        this.completedAt = LocalDateTime.now();
        this.resultMessage = resultMessage;
    }

    // cancel 취소 처리
    public void cancel(String resultMessage) {
        if (this.commandStatus == CommandStatus.SUCCESS ||
                this.commandStatus == CommandStatus.FAILED) {
            throw new IllegalStateException("이미 완료된 명령은 취소할 수 없습니다.");
        }

        this.commandStatus = CommandStatus.CANCELLED;
        this.completedAt = LocalDateTime.now();
        this.resultMessage = resultMessage;
    }

    // delete 삭제
    public void delete() {
        this.deleted = true;
    }

    public boolean isPendingOrProcessing() {
        return this.commandStatus == CommandStatus.PENDING ||
                this.commandStatus == CommandStatus.PROCESSING;
    }

    // 방치 명령 여부 — PROCESSING은 처리 시작 시각, PENDING은 요청 시각 기준
    public boolean isStale(LocalDateTime now) {
        if (!isPendingOrProcessing()) {
            return false;
        }

        LocalDateTime baseTime = this.processedAt == null
                ? this.requestedAt
                : this.processedAt;

        return baseTime.isBefore(now.minusMinutes(STALE_COMMAND_TIMEOUT_MINUTES));
    }

    // 생성 시각 초기화
    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.modifiedAt = now;
    }

    // 수정 시각 갱신
    @PreUpdate
    public void preUpdate() {
        this.modifiedAt = LocalDateTime.now();
    }
}

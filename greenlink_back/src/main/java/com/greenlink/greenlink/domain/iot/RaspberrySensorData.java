package com.greenlink.greenlink.domain.iot;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// RaspberrySensorData — 도메인 모델
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "raspberry_sensor_data")
public class RaspberrySensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 환경 센서 데이터는 식물 단위가 아니라 재배 공간 단위다.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id", nullable = false)
    private GrowSpace growSpace;

    // 데이터를 보낸 라즈베리파이 기기
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "iot_device_id", nullable = false)
    private IotDevice iotDevice;

    private Double temperature;

    private Double humidity;

    private Double light;

    @Column(nullable = false)
    private LocalDateTime measuredAt;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // RaspberrySensorData 생성
    @Builder
    private RaspberrySensorData(
            GrowSpace growSpace,
            IotDevice iotDevice,
            Double temperature,
            Double humidity,
            Double light,
            LocalDateTime measuredAt
    ) {
        if (!iotDevice.isRaspberryPi()) {
            throw new IllegalStateException("라즈베리파이 기기만 환경 센서 데이터를 전송할 수 있습니다.");
        }

        this.growSpace = growSpace;
        this.iotDevice = iotDevice;
        this.temperature = temperature;
        this.humidity = humidity;
        this.light = light;
        this.measuredAt = measuredAt == null ? LocalDateTime.now() : measuredAt;
        this.deleted = false;
    }

    // create 생성
    public static RaspberrySensorData create(
            GrowSpace growSpace,
            IotDevice iotDevice,
            Double temperature,
            Double humidity,
            Double light,
            LocalDateTime measuredAt
    ) {
        return RaspberrySensorData.builder()
                .growSpace(growSpace)
                .iotDevice(iotDevice)
                .temperature(temperature)
                .humidity(humidity)
                .light(light)
                .measuredAt(measuredAt)
                .build();
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

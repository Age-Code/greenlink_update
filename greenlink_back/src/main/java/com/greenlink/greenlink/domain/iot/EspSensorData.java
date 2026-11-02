package com.greenlink.greenlink.domain.iot;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// EspSensorData — 도메인 모델
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "esp_sensor_data")
public class EspSensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ESP가 속한 재배 공간
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id")
    private GrowSpace growSpace;

    // ESP가 담당하는 특정 식물
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 데이터를 보낸 ESP32 기기
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "iot_device_id", nullable = false)
    private IotDevice iotDevice;

    private Integer soilMoistureRaw;

    private Double soilMoisturePercent;

    @Column(nullable = false)
    private LocalDateTime measuredAt;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // EspSensorData 생성
    @Builder
    private EspSensorData(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice iotDevice,
            Integer soilMoistureRaw,
            Double soilMoisturePercent,
            LocalDateTime measuredAt
    ) {
        if (!iotDevice.isEsp32()) {
            throw new IllegalStateException("ESP32 기기만 토양수분 데이터를 전송할 수 있습니다.");
        }

        this.growSpace = growSpace;
        this.userPlant = userPlant;
        this.iotDevice = iotDevice;
        this.soilMoistureRaw = soilMoistureRaw;
        this.soilMoisturePercent = soilMoisturePercent;
        this.measuredAt = measuredAt == null ? LocalDateTime.now() : measuredAt;
        this.deleted = false;
    }

    // create 생성
    public static EspSensorData create(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice iotDevice,
            Integer soilMoistureRaw,
            Double soilMoisturePercent,
            LocalDateTime measuredAt
    ) {
        return EspSensorData.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .iotDevice(iotDevice)
                .soilMoistureRaw(soilMoistureRaw)
                .soilMoisturePercent(soilMoisturePercent)
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

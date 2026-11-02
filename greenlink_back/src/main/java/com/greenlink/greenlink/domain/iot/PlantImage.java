package com.greenlink.greenlink.domain.iot;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// PlantImage — 도메인 모델
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "plant_image")
public class PlantImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 사진이 촬영된 재배 공간
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id", nullable = false)
    private GrowSpace growSpace;

    // 특정 식물 사진이면 userPlant가 들어간다. — 공간 전체 사진이면 null 가능.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id")
    private UserPlant userPlant;

    // 사진을 촬영한 라즈베리파이
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "iot_device_id", nullable = false)
    private IotDevice iotDevice;

    @Column(nullable = false, length = 500)
    private String imageUrl;

    @Column(length = 255)
    private String originalFilename;

    @Column(nullable = false)
    private LocalDateTime capturedAt;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // PlantImage 생성
    @Builder
    private PlantImage(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice iotDevice,
            String imageUrl,
            String originalFilename,
            LocalDateTime capturedAt
    ) {
        if (!iotDevice.isRaspberryPi()) {
            throw new IllegalStateException("라즈베리파이 기기만 식물 이미지를 업로드할 수 있습니다.");
        }

        this.growSpace = growSpace;
        this.userPlant = userPlant;
        this.iotDevice = iotDevice;
        this.imageUrl = imageUrl;
        this.originalFilename = originalFilename;
        this.capturedAt = capturedAt == null ? LocalDateTime.now() : capturedAt;
        this.deleted = false;
    }

    // create 생성
    public static PlantImage create(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice iotDevice,
            String imageUrl,
            String originalFilename,
            LocalDateTime capturedAt
    ) {
        return PlantImage.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .iotDevice(iotDevice)
                .imageUrl(imageUrl)
                .originalFilename(originalFilename)
                .capturedAt(capturedAt)
                .build();
    }

    public boolean isPlantSpecificImage() {
        return this.userPlant != null;
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

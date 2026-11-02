package com.greenlink.greenlink.domain.ai;

import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.iot.PlantImage;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// AiPlantImage — 도메인 모델
@Entity
@Table(name = "ai_plant_image")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class AiPlantImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ai_plant_image_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plant_image_id", nullable = false)
    private PlantImage plantImage;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    @Column(name = "original_image_url", nullable = false, columnDefinition = "TEXT")
    private String originalImageUrl;

    @Column(name = "ai_image_url", nullable = false, columnDefinition = "TEXT")
    private String aiImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private AiImageStatus status;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "modified_at", nullable = false)
    private LocalDateTime modifiedAt;

    // 생성 시각 초기화
    @PrePersist
    public void prePersist() {
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

        if (status == null) {
            status = AiImageStatus.SUCCESS;
        }
    }

    // 수정 시각 갱신
    @PreUpdate
    public void preUpdate() {
        modifiedAt = LocalDateTime.now();
    }

    // AI 결과 URL 갱신 — 같은 원본 이미지에 대한 재처리 결과를 반영한다.
    public void updateAiImageUrl(String aiImageUrl) {
        this.aiImageUrl = aiImageUrl;
        this.status = AiImageStatus.SUCCESS;
        this.errorMessage = null;
    }

    // AI 처리 성공 표시
    public static AiPlantImage success(
            PlantImage plantImage,
            UserPlant userPlant,
            String aiImageUrl
    ) {
        return AiPlantImage.builder()
                .plantImage(plantImage)
                .userPlant(userPlant)
                .originalImageUrl(plantImage.getImageUrl())
                .aiImageUrl(aiImageUrl)
                .status(AiImageStatus.SUCCESS)
                .deleted(false)
                .build();
    }
}

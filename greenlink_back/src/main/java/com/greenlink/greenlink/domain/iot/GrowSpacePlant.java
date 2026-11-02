package com.greenlink.greenlink.domain.iot;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(
        name = "grow_space_plant",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uq_grow_space_plant_user_plant",
                        columnNames = "user_plant_id"
                )
        }
)
// GrowSpacePlant — 도메인 모델
public class GrowSpacePlant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 식물이 배치된 재배 공간
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id", nullable = false)
    private GrowSpace growSpace;

    // 재배 공간에 연결된 사용자 식물
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    @Column(nullable = false)
    private Boolean active;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // GrowSpacePlant 생성
    @Builder
    private GrowSpacePlant(
            GrowSpace growSpace,
            UserPlant userPlant
    ) {
        this.growSpace = growSpace;
        this.userPlant = userPlant;
        this.active = true;
        this.deleted = false;
    }

    // 재배 공간과 식물 연결 처리
    public static GrowSpacePlant connect(
            GrowSpace growSpace,
            UserPlant userPlant
    ) {
        return GrowSpacePlant.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .build();
    }

    // 재배 공간과 식물 연결 해제 처리
    public void disconnect() {
        this.active = false;
        this.deleted = true;
    }

    // 생성 시각 초기화
    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.modifiedAt = now;

        if (this.active == null) {
            this.active = true;
        }
    }

    // 수정 시각 갱신
    @PreUpdate
    public void preUpdate() {
        this.modifiedAt = LocalDateTime.now();
    }
}

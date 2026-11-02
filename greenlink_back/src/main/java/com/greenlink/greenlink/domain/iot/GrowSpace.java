package com.greenlink.greenlink.domain.iot;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

// GrowSpace — 도메인 모델
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "grow_space")
public class GrowSpace {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 재배 공간 이름
    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private Boolean active;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // GrowSpace 생성
    @Builder
    private GrowSpace(
            String name,
            String description
    ) {
        this.name = name;
        this.description = description;
        this.active = true;
        this.deleted = false;
    }

    // create 생성
    public static GrowSpace create(
            String name,
            String description
    ) {
        return GrowSpace.builder()
                .name(name)
                .description(description)
                .build();
    }

    // update Info 수정
    public void updateInfo(
            String name,
            String description
    ) {
        this.name = name;
        this.description = description;
    }

    // 비활성화 처리
    public void deactivate() {
        this.active = false;
    }

    // 활성화 처리
    public void activate() {
        this.active = true;
    }

    // delete 삭제
    public void delete() {
        this.deleted = true;
        this.active = false;
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

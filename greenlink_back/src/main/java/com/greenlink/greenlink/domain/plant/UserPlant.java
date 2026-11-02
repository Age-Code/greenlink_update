package com.greenlink.greenlink.domain.plant;

import org.hibernate.annotations.ColumnDefault;
import com.greenlink.greenlink.common.BaseEntity;
import com.greenlink.greenlink.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

// UserPlant — 도메인 모델
@Getter
@Entity
@Table(name = "user_plant")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserPlant extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 이 식물을 키우는 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 어떤 식물 종인지
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plant_id", nullable = false)
    private Plant plant;

    // 사용자가 붙인 식물 별명
    @Column(length = 50)
    private String nickname;

    // 식물 상태: GROWING, HARVESTABLE, HARVESTED
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private UserPlantStatus status;

    // 심은 날짜
    @Column(name = "planted_at", nullable = false)
    private LocalDateTime plantedAt;

    // 수확 날짜
    @Column(name = "harvested_at")
    private LocalDateTime harvestedAt;

    // 대표 이미지
    @Column(name = "image_url", length = 500)
    private String imageUrl;

    // 영양제로 단축된 성장일 수 — 영양제 1개당 1일
    @ColumnDefault("0")
    @Column(name = "growth_boost_days", nullable = false)
    private int growthBoostDays = 0;

    // UserPlant 생성
    private UserPlant(User user, Plant plant, String nickname, LocalDateTime plantedAt, String imageUrl) {
        this.user = user;
        this.plant = plant;
        this.nickname = nickname;
        this.status = UserPlantStatus.GROWING;
        this.plantedAt = plantedAt;
        this.imageUrl = imageUrl;
    }

    // create 생성
    public static UserPlant create(User user, Plant plant, String nickname) {
        return new UserPlant(user, plant, nickname, LocalDateTime.now(), plant.getImageUrl());
    }

    // update Nickname 수정
    public void updateNickname(String nickname) {
        this.nickname = nickname;
    }

    public boolean isOwner(User user) {
        return this.user.getId().equals(user.getId());
    }

    // 수확 가능 날짜 — 식재일 + 성장일 - 영양제 단축일 (식재일보다 앞당겨지지 않음)
    public LocalDate getHarvestableDate() {
        int effectiveGrowthDays = Math.max(this.plant.getGrowthDays() - this.growthBoostDays, 0);
        return this.plantedAt.toLocalDate().plusDays(effectiveGrowthDays);
    }

    public boolean isHarvestable(LocalDate today) {
        return !today.isBefore(getHarvestableDate());
    }

    // 영양제 효과 적용 — 성장 중인 식물만 성장일 1일 단축
    public void applyNutrient(LocalDate today) {
        refreshHarvestableStatus(today);

        if (this.status != UserPlantStatus.GROWING) {
            throw new IllegalStateException("성장 중인 식물에만 영양제를 사용할 수 있습니다.");
        }

        this.growthBoostDays += 1;
        refreshHarvestableStatus(today);
    }

    // 수확 가능 상태 갱신
    public void refreshHarvestableStatus(LocalDate today) {
        if (this.status == UserPlantStatus.GROWING && isHarvestable(today)) {
            this.status = UserPlantStatus.HARVESTABLE;
        }
    }

    // 수확 처리
    public void harvest(LocalDateTime harvestedAt) {
        if (this.status == UserPlantStatus.HARVESTED) {
            throw new IllegalStateException("이미 수확 완료된 식물입니다.");
        }

        this.status = UserPlantStatus.HARVESTED;
        this.harvestedAt = harvestedAt;
    }

    public long getDaysAfterPlanting(LocalDate today) {
        return ChronoUnit.DAYS.between(this.plantedAt.toLocalDate(), today);
    }

    public long getRemainingDays(LocalDate today) {
        LocalDate harvestableDate = getHarvestableDate();
        long remainingDays = ChronoUnit.DAYS.between(today, harvestableDate);

        return Math.max(remainingDays, 0);
    }
}
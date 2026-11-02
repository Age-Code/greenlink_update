package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.repository.PlantImageRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

// 오래된 식물 사진 정리 — 서버 디스크가 무한히 차지 않도록 보관 기간이 지난 사진을 지운다.
// 각 식물(또는 공간)의 가장 최근 사진은 썸네일로 쓰이므로 기간과 무관하게 남긴다.
@Slf4j
@Service
public class PlantImageCleanupService {

    private final PlantImageRepository plantImageRepository;
    private final ImageStorageService imageStorageService;
    private final int retentionDays;

    public PlantImageCleanupService(
            PlantImageRepository plantImageRepository,
            ImageStorageService imageStorageService,
            @Value("${greenlink.storage.image-retention-days:30}") int retentionDays
    ) {
        this.plantImageRepository = plantImageRepository;
        this.imageStorageService = imageStorageService;
        this.retentionDays = retentionDays;
    }

    // 매일 새벽 4시 실행
    @Scheduled(cron = "0 0 4 * * *")
    @Transactional
    public int cleanUpOldImages() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(retentionDays);
        List<PlantImage> oldImages =
                plantImageRepository.findAllByCapturedAtBeforeAndDeletedFalseOrderByCapturedAtDesc(cutoff);

        Set<Long> keptLatest = new HashSet<>();
        int removed = 0;

        for (PlantImage image : oldImages) {
            if (isLatestOfItsOwner(image, keptLatest)) {
                continue;
            }

            imageStorageService.deleteByPublicPath(image.getImageUrl());
            image.markDeleted();
            removed++;
        }

        if (removed > 0) {
            log.info("[IMAGE_CLEANUP] {}일 지난 사진 {}장 삭제", retentionDays, removed);
        }

        return removed;
    }

    // 식물(없으면 공간)별 최신 사진인지 — 그 식물의 최신 사진이 보관 기간 밖에 있을 때만 해당
    private boolean isLatestOfItsOwner(PlantImage image, Set<Long> keptLatest) {
        PlantImage latest = image.getUserPlant() != null
                ? plantImageRepository.findFirstByUserPlantAndDeletedFalseOrderByCapturedAtDesc(image.getUserPlant())
                        .orElse(null)
                : plantImageRepository.findFirstByGrowSpaceAndUserPlantIsNullAndDeletedFalseOrderByCapturedAtDesc(image.getGrowSpace())
                        .orElse(null);

        if (latest != null && latest.getId().equals(image.getId())) {
            keptLatest.add(image.getId());
            return true;
        }

        return false;
    }
}

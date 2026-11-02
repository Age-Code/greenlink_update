package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.ai.AiPlantImage;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.dto.ai.AiPlantImageDto;
import com.greenlink.greenlink.repository.AiPlantImageRepository;
import com.greenlink.greenlink.repository.PlantImageRepository;
import lombok.RequiredArgsConstructor;
import java.net.URI;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// AiPlantImageService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
public class AiPlantImageService {

    private static final String ORIGINAL_IMAGE_PREFIX = "greenlink/userplant/";
    private static final String AI_IMAGE_PREFIX = "greenlink/ai/userplant/";

    private final PlantImageRepository plantImageRepository;
    private final AiPlantImageRepository aiPlantImageRepository;

    // save Ai Image Result 저장
    @Transactional
    public AiPlantImageDto.AiImageResDto saveAiImageResult(
            Long plantImageId,
            AiPlantImageDto.SaveAiImageReqDto request
    ) {
        if (request.getFinalAiUrl() == null || request.getFinalAiUrl().isBlank()) {
            throw new IllegalArgumentException("finalAiUrl은 필수입니다.");
        }

        PlantImage plantImage = plantImageRepository.findByIdAndDeletedFalse(plantImageId)
                .orElseThrow(() -> new IllegalArgumentException("원본 식물 이미지를 찾을 수 없습니다."));

        UserPlant userPlant = plantImage.getUserPlant();

        if (userPlant == null) {
            throw new IllegalStateException("원본 이미지에 연결된 userPlant가 없습니다.");
        }

        // 다른 원본에서 만든 결과로 덮어쓰지 못하도록 원본 URL에서 기대 결과 URL을 계산해 대조한다.
        String expectedAiUrl = buildExpectedAiUrl(plantImage.getImageUrl());

        if (!expectedAiUrl.equals(request.getFinalAiUrl())) {
            throw new IllegalArgumentException("finalAiUrl이 원본 이미지와 일치하지 않습니다.");
        }

        // callback이 재시도되어도 원본 이미지당 결과가 하나만 유지되도록 갱신한다.
        AiPlantImage existing = aiPlantImageRepository
                .findTopByPlantImageAndDeletedFalseOrderByIdDesc(plantImage)
                .orElse(null);

        if (existing != null) {
            existing.updateAiImageUrl(request.getFinalAiUrl());

            return AiPlantImageDto.AiImageResDto.from(existing);
        }

        AiPlantImage aiPlantImage = AiPlantImage.success(
                plantImage,
                userPlant,
                request.getFinalAiUrl()
        );

        AiPlantImage saved = aiPlantImageRepository.save(aiPlantImage);

        return AiPlantImageDto.AiImageResDto.from(saved);
    }

    // 기대 AI 결과 URL 생성 — Worker와 같은 규칙(greenlink/ai/userplant/{원본 stem}.png)
    static String buildExpectedAiUrl(String originalImageUrl) {
        URI uri;

        try {
            uri = URI.create(originalImageUrl);
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("원본 이미지 URL 형식이 올바르지 않습니다.");
        }

        String path = uri.getPath();

        if (uri.getScheme() == null || uri.getHost() == null || path == null
                || !path.startsWith("/" + ORIGINAL_IMAGE_PREFIX)) {
            throw new IllegalStateException("원본 이미지 URL이 AI 처리 대상 경로가 아닙니다.");
        }

        String filename = path.substring(ORIGINAL_IMAGE_PREFIX.length() + 1);
        int dotIndex = filename.lastIndexOf('.');

        if (filename.isEmpty() || filename.contains("/") || dotIndex <= 0) {
            throw new IllegalStateException("원본 이미지 파일명이 올바르지 않습니다.");
        }

        String stem = filename.substring(0, dotIndex);

        return uri.getScheme() + "://" + uri.getHost() + "/" + AI_IMAGE_PREFIX + stem + ".png";
    }
}

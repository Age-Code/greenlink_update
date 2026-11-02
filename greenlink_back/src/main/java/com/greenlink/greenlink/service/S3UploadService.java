package com.greenlink.greenlink.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.UUID;

// S3 업로드 서비스 — MIME/크기 검증 후 업로드
@Service
@RequiredArgsConstructor
public class S3UploadService {

    private static final String USER_PLANT_IMAGE_PREFIX = "greenlink/userplant/";

    private final S3Client s3Client;

    @Value("${cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${cloud.aws.region}")
    private String region;

    // upload User Plant Image 처리
    public String uploadUserPlantImage(
            MultipartFile file,
            Long userPlantId
    ) {
        validateImageFile(file);
        validateS3Configuration();

        String originalFilename = file.getOriginalFilename();
        String storedFilename = createStoredFilename(originalFilename, userPlantId);
        String key = USER_PLANT_IMAGE_PREFIX + storedFilename;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .build();

            s3Client.putObject(
                    putObjectRequest,
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize())
            );

            return createS3Url(key);
        } catch (IOException e) {
            throw new IllegalStateException("S3 이미지 업로드에 실패했습니다.");
        }
    }

    // S3 설정 검증 — 새 버킷 구성 누락 시 업로드 전에 명확히 실패
    private void validateS3Configuration() {
        if (bucket == null || bucket.isBlank()) {
            throw new IllegalStateException("S3_BUCKET 환경변수가 필요합니다.");
        }

        if (region == null || region.isBlank()) {
            throw new IllegalStateException("AWS_REGION 환경변수가 필요합니다.");
        }
    }

    // 이미지 파일 검증 — MIME/크기 제한 확인
    private void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 이미지 파일이 필요합니다.");
        }

        long maxSize = 20 * 1024 * 1024;

        if (file.getSize() > maxSize) {
            throw new IllegalArgumentException("이미지 파일은 20MB 이하만 업로드할 수 있습니다.");
        }

        String originalFilename = file.getOriginalFilename();

        if (originalFilename == null || originalFilename.isBlank()) {
            throw new IllegalArgumentException("파일명이 올바르지 않습니다.");
        }

        String extension = getExtension(originalFilename).toLowerCase();

        Map<String, String> contentTypeByExtension = Map.of(
                "jpg", "image/jpeg",
                "jpeg", "image/jpeg",
                "png", "image/png",
                "webp", "image/webp"
        );
        String expectedContentType = contentTypeByExtension.get(extension);

        if (expectedContentType == null) {
            throw new IllegalArgumentException("jpg, jpeg, png, webp 파일만 업로드할 수 있습니다.");
        }

        if (!expectedContentType.equals(file.getContentType())) {
            throw new IllegalArgumentException("파일 확장자와 이미지 MIME type이 일치해야 합니다.");
        }
    }

    // create Stored Filename 생성
    private String createStoredFilename(String originalFilename, Long userPlantId) {
        String extension = getExtension(originalFilename).toLowerCase();
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);

        if (userPlantId == null) {
            return "grow-space-" + timestamp + "-" + uuid + "." + extension;
        }

        return "user-plant-" + userPlantId + "-" + timestamp + "-" + uuid + "." + extension;
    }

    private String getExtension(String filename) {
        int dotIndex = filename.lastIndexOf(".");

        if (dotIndex == -1 || dotIndex == filename.length() - 1) {
            throw new IllegalArgumentException("파일 확장자가 없습니다.");
        }

        return filename.substring(dotIndex + 1);
    }

    // create S3 Url 생성
    private String createS3Url(String key) {
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }
}

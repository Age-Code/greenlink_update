package com.greenlink.greenlink.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.UUID;

// 식물 사진 저장 — 서버 디스크(Docker 볼륨)에 저장하고 /images/** 경로로 제공한다.
@Service
public class ImageStorageService {

    // DB에 저장하는 공개 경로 접두사 — WebMvcConfig의 리소스 핸들러와 같아야 한다.
    public static final String PUBLIC_PATH_PREFIX = "/images/";
    private static final String USER_PLANT_DIR = "userplant";
    private static final long MAX_SIZE_BYTES = 20 * 1024 * 1024;

    private static final Map<String, String> CONTENT_TYPE_BY_EXTENSION = Map.of(
            "jpg", "image/jpeg",
            "jpeg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp"
    );

    private final Path rootDir;

    public ImageStorageService(@Value("${greenlink.storage.image-dir}") String imageDir) {
        this.rootDir = Path.of(imageDir).toAbsolutePath().normalize();
    }

    public Path getRootDir() {
        return rootDir;
    }

    // 식물 사진 저장 — 반환값은 "/images/userplant/{파일명}" 형태의 서버 상대 경로
    public String storeUserPlantImage(MultipartFile file, Long userPlantId) {
        validateImageFile(file);

        String storedFilename = createStoredFilename(file.getOriginalFilename(), userPlantId);
        Path dir = rootDir.resolve(USER_PLANT_DIR);
        Path target = dir.resolve(storedFilename);
        Path temp = dir.resolve(storedFilename + ".part");

        try {
            Files.createDirectories(dir);

            // 임시 파일에 다 쓴 뒤 옮겨서, 쓰는 도중의 파일이 공개되지 않게 한다.
            try (InputStream input = file.getInputStream()) {
                Files.copy(input, temp, StandardCopyOption.REPLACE_EXISTING);
            }
            Files.move(temp, target, StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException e) {
            try {
                Files.deleteIfExists(temp);
            } catch (IOException ignored) {
                // 임시 파일 정리 실패는 저장 실패 원인보다 덜 중요하다.
            }
            throw new IllegalStateException("이미지 저장에 실패했습니다.");
        }

        return PUBLIC_PATH_PREFIX + USER_PLANT_DIR + "/" + storedFilename;
    }

    // 저장된 사진 삭제 — 이 서비스가 만든 경로만 지운다. 이미 없으면 무시
    public void deleteByPublicPath(String publicPath) {
        if (publicPath == null || !publicPath.startsWith(PUBLIC_PATH_PREFIX)) {
            return;
        }

        Path target = rootDir.resolve(publicPath.substring(PUBLIC_PATH_PREFIX.length())).normalize();

        if (!target.startsWith(rootDir)) {
            return;
        }

        try {
            Files.deleteIfExists(target);
        } catch (IOException e) {
            throw new IllegalStateException("이미지 삭제에 실패했습니다: " + publicPath);
        }
    }

    // 이미지 파일 검증 — 크기, 확장자, MIME 일치
    private void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 이미지 파일이 필요합니다.");
        }

        if (file.getSize() > MAX_SIZE_BYTES) {
            throw new IllegalArgumentException("이미지 파일은 20MB 이하만 업로드할 수 있습니다.");
        }

        String originalFilename = file.getOriginalFilename();

        if (originalFilename == null || originalFilename.isBlank()) {
            throw new IllegalArgumentException("파일명이 올바르지 않습니다.");
        }

        String expectedContentType = CONTENT_TYPE_BY_EXTENSION.get(getExtension(originalFilename).toLowerCase());

        if (expectedContentType == null) {
            throw new IllegalArgumentException("jpg, jpeg, png, webp 파일만 업로드할 수 있습니다.");
        }

        if (!expectedContentType.equals(file.getContentType())) {
            throw new IllegalArgumentException("파일 확장자와 이미지 MIME type이 일치해야 합니다.");
        }
    }

    // 저장 파일명 — 원본 파일명은 쓰지 않고 식물 ID·시각·난수로 만든다(경로 조작 방지)
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
}

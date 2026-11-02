package com.greenlink.greenlink.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImageStorageServiceTest {

    @TempDir
    Path tempDir;

    @Test
    void storesImageOnDiskAndReturnsPublicPath() throws Exception {
        ImageStorageService service = new ImageStorageService(tempDir.toString());
        MockMultipartFile image = new MockMultipartFile("file", "plant.PNG", "image/png", new byte[]{1, 2, 3});

        String publicPath = service.storeUserPlantImage(image, 42L);

        assertThat(publicPath).matches("/images/userplant/user-plant-42-\\d{8}-\\d{6}-[0-9a-f]{8}\\.png");
        Path stored = tempDir.resolve(publicPath.substring("/images/".length()));
        assertThat(Files.readAllBytes(stored)).containsExactly(1, 2, 3);
        try (var files = Files.list(stored.getParent())) {
            assertThat(files).noneMatch(path -> path.toString().endsWith(".part"));
        }
    }

    @Test
    void deletesOnlyFilesInsideStorageRoot() throws Exception {
        ImageStorageService service = new ImageStorageService(tempDir.resolve("root").toString());
        String publicPath = service.storeUserPlantImage(
                new MockMultipartFile("file", "a.jpg", "image/jpeg", new byte[]{1}), 1L);
        Path outside = Files.writeString(tempDir.resolve("outside.txt"), "keep");

        service.deleteByPublicPath("/images/../outside.txt");
        service.deleteByPublicPath("https://example.com/other.jpg");
        service.deleteByPublicPath(publicPath);

        assertThat(outside).exists();
        assertThat(tempDir.resolve("root").resolve(publicPath.substring("/images/".length()))).doesNotExist();
    }

    @Test
    void rejectsExtensionAndMimeMismatch() {
        ImageStorageService service = new ImageStorageService(tempDir.toString());

        assertThatThrownBy(() -> service.storeUserPlantImage(
                new MockMultipartFile("file", "plant.png", "image/jpeg", new byte[]{1}), 1L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("파일 확장자와 이미지 MIME type이 일치해야 합니다.");
    }

    @Test
    void rejectsUnsupportedExtension() {
        ImageStorageService service = new ImageStorageService(tempDir.toString());

        assertThatThrownBy(() -> service.storeUserPlantImage(
                new MockMultipartFile("file", "plant.gif", "image/gif", new byte[]{1}), 1L))
                .isInstanceOf(IllegalArgumentException.class);
    }
}

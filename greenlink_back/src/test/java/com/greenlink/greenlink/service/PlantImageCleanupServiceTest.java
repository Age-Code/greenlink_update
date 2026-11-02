package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.repository.PlantImageRepository;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class PlantImageCleanupServiceTest {

    @Test
    void deletesExpiredImagesButKeepsEachPlantsLatestThumbnail() {
        PlantImageRepository repository = mock(PlantImageRepository.class);
        ImageStorageService storage = mock(ImageStorageService.class);
        PlantImageCleanupService service = new PlantImageCleanupService(repository, storage, 30);

        UserPlant userPlant = userPlant();
        PlantImage latestButOld = image(1L, userPlant, "/images/userplant/latest.jpg", 40);
        PlantImage older = image(2L, userPlant, "/images/userplant/older.jpg", 41);

        given(repository.findAllByCapturedAtBeforeAndDeletedFalseOrderByCapturedAtDesc(any()))
                .willReturn(List.of(latestButOld, older));
        given(repository.findFirstByUserPlantAndDeletedFalseOrderByCapturedAtDesc(userPlant))
                .willReturn(Optional.of(latestButOld));

        int removed = service.cleanUpOldImages();

        assertThat(removed).isEqualTo(1);
        verify(storage).deleteByPublicPath("/images/userplant/older.jpg");
        verify(storage, never()).deleteByPublicPath("/images/userplant/latest.jpg");
        assertThat(older.isDeleted()).isTrue();
        assertThat(latestButOld.isDeleted()).isFalse();
    }

    private UserPlant userPlant() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        return UserPlant.create(user, Plant.create("바질", "HERB", null, null, 30), "바질이");
    }

    private PlantImage image(Long id, UserPlant userPlant, String path, int daysAgo) {
        GrowSpace growSpace = GrowSpace.create("space", null);
        IotDevice pi = IotDevice.createRaspberryPi(growSpace, "pi", "key");
        PlantImage image = PlantImage.create(growSpace, userPlant, pi, path, "a.jpg",
                LocalDateTime.now().minusDays(daysAgo));
        ReflectionTestUtils.setField(image, "id", id);
        return image;
    }
}

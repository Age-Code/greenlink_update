package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.ai.AiPlantImage;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.ai.AiPlantImageDto;
import com.greenlink.greenlink.repository.AiPlantImageRepository;
import com.greenlink.greenlink.repository.PlantImageRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AiPlantImageServiceTest {

    private static final String ORIGINAL_URL =
            "https://bucket.s3.ap-northeast-2.amazonaws.com/greenlink/userplant/user-plant-5-20260101-120000-abcd1234.jpg";
    private static final String EXPECTED_AI_URL =
            "https://bucket.s3.ap-northeast-2.amazonaws.com/greenlink/ai/userplant/user-plant-5-20260101-120000-abcd1234.png";

    @Mock
    private PlantImageRepository plantImageRepository;
    @Mock
    private AiPlantImageRepository aiPlantImageRepository;

    @InjectMocks
    private AiPlantImageService aiPlantImageService;

    @Test
    void repeatedCallbackUpdatesExistingResultInsteadOfCreatingAnother() {
        PlantImage plantImage = plantImage();
        AiPlantImage existing = AiPlantImage.success(
                plantImage,
                plantImage.getUserPlant(),
                EXPECTED_AI_URL
        );

        given(plantImageRepository.findByIdAndDeletedFalse(1L))
                .willReturn(Optional.of(plantImage));
        given(aiPlantImageRepository.findTopByPlantImageAndDeletedFalseOrderByIdDesc(plantImage))
                .willReturn(Optional.of(existing));

        AiPlantImageDto.AiImageResDto response = aiPlantImageService.saveAiImageResult(
                1L,
                new AiPlantImageDto.SaveAiImageReqDto(EXPECTED_AI_URL)
        );

        assertThat(response.getAiImageUrl()).isEqualTo(EXPECTED_AI_URL);
        assertThat(existing.getAiImageUrl()).isEqualTo(EXPECTED_AI_URL);
        verify(aiPlantImageRepository, never()).save(any(AiPlantImage.class));
    }

    @Test
    void firstCallbackCreatesResult() {
        PlantImage plantImage = plantImage();

        given(plantImageRepository.findByIdAndDeletedFalse(1L))
                .willReturn(Optional.of(plantImage));
        given(aiPlantImageRepository.findTopByPlantImageAndDeletedFalseOrderByIdDesc(plantImage))
                .willReturn(Optional.empty());
        given(aiPlantImageRepository.save(any(AiPlantImage.class)))
                .willAnswer(invocation -> invocation.getArgument(0));

        AiPlantImageDto.AiImageResDto response = aiPlantImageService.saveAiImageResult(
                1L,
                new AiPlantImageDto.SaveAiImageReqDto(EXPECTED_AI_URL)
        );

        assertThat(response.getAiImageUrl()).isEqualTo(EXPECTED_AI_URL);
        verify(aiPlantImageRepository).save(any(AiPlantImage.class));
    }

    @Test
    void callbackWithResultFromAnotherImageIsRejected() {
        PlantImage plantImage = plantImage();

        given(plantImageRepository.findByIdAndDeletedFalse(1L))
                .willReturn(Optional.of(plantImage));

        assertThatThrownBy(() -> aiPlantImageService.saveAiImageResult(
                1L,
                new AiPlantImageDto.SaveAiImageReqDto(
                        "https://bucket.s3.ap-northeast-2.amazonaws.com/greenlink/ai/userplant/user-plant-9-other.png"
                )
        )).isInstanceOf(IllegalArgumentException.class);

        verify(aiPlantImageRepository, never()).save(any(AiPlantImage.class));
    }

    @Test
    void expectedAiUrlRejectsOriginalOutsideUserPlantPrefix() {
        assertThatThrownBy(() -> AiPlantImageService.buildExpectedAiUrl(
                "https://bucket.s3.ap-northeast-2.amazonaws.com/other/a.jpg"
        )).isInstanceOf(IllegalStateException.class);
    }

    private PlantImage plantImage() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);
        UserPlant userPlant = UserPlant.create(user, plant, "바질이");
        GrowSpace growSpace = GrowSpace.create("test-space", null);
        IotDevice raspberryDevice = IotDevice.createRaspberryPi(growSpace, "test-pi", "test-device-key");

        return PlantImage.create(
                growSpace,
                userPlant,
                raspberryDevice,
                ORIGINAL_URL,
                "original.jpg",
                LocalDateTime.now()
        );
    }
}

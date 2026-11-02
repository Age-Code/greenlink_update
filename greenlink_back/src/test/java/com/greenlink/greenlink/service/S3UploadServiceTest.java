package com.greenlink.greenlink.service;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class S3UploadServiceTest {

    @Test
    void uploadUsesConfiguredBucketAndRegionWithExpectedObjectMetadata() {
        S3Client s3Client = mock(S3Client.class);
        S3UploadService service = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(service, "bucket", "greenlink-images");
        ReflectionTestUtils.setField(service, "region", "ap-northeast-2");

        MockMultipartFile image = new MockMultipartFile(
                "file",
                "plant.PNG",
                "image/png",
                new byte[]{1, 2, 3}
        );

        String uploadedUrl = service.uploadUserPlantImage(image, 42L);

        ArgumentCaptor<PutObjectRequest> requestCaptor =
                ArgumentCaptor.forClass(PutObjectRequest.class);
        ArgumentCaptor<RequestBody> bodyCaptor =
                ArgumentCaptor.forClass(RequestBody.class);

        verify(s3Client).putObject(requestCaptor.capture(), bodyCaptor.capture());

        PutObjectRequest request = requestCaptor.getValue();
        assertThat(request.bucket()).isEqualTo("greenlink-images");
        assertThat(request.key())
                .matches(
                        "greenlink/userplant/"
                                + "user-plant-42-\\d{8}-\\d{6}-[0-9a-f]{8}\\.png"
                );
        assertThat(request.contentType()).isEqualTo("image/png");
        assertThat(request.contentLength()).isEqualTo(image.getSize());
        assertThat(bodyCaptor.getValue().optionalContentLength())
                .contains(image.getSize());
        assertThat(uploadedUrl).isEqualTo(
                "https://greenlink-images.s3.ap-northeast-2.amazonaws.com/"
                        + request.key()
        );
    }

    @Test
    void uploadFailsBeforeCallingS3WhenBucketIsNotConfigured() {
        S3Client s3Client = mock(S3Client.class);
        S3UploadService service = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(service, "bucket", "");
        ReflectionTestUtils.setField(service, "region", "ap-northeast-2");

        MockMultipartFile image = new MockMultipartFile(
                "file",
                "plant.jpg",
                "image/jpeg",
                new byte[]{1}
        );

        assertThatThrownBy(() -> service.uploadUserPlantImage(image, 1L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("S3_BUCKET 환경변수가 필요합니다.");

        verifyNoInteractions(s3Client);
    }

    @Test
    void uploadFailsBeforeCallingS3WhenRegionIsNotConfigured() {
        S3Client s3Client = mock(S3Client.class);
        S3UploadService service = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(service, "bucket", "greenlink-images");
        ReflectionTestUtils.setField(service, "region", " ");

        MockMultipartFile image = new MockMultipartFile(
                "file",
                "plant.jpg",
                "image/jpeg",
                new byte[]{1}
        );

        assertThatThrownBy(() -> service.uploadUserPlantImage(image, 1L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("AWS_REGION 환경변수가 필요합니다.");

        verifyNoInteractions(s3Client);
    }

    @Test
    void uploadRejectsContentTypeThatDoesNotMatchExtension() {
        S3Client s3Client = mock(S3Client.class);
        S3UploadService service = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(service, "bucket", "greenlink-images");
        ReflectionTestUtils.setField(service, "region", "ap-northeast-2");

        MockMultipartFile image = new MockMultipartFile(
                "file",
                "plant.jpg",
                "image/png",
                new byte[]{1}
        );

        assertThatThrownBy(() -> service.uploadUserPlantImage(image, 1L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("파일 확장자와 이미지 MIME type이 일치해야 합니다.");

        verifyNoInteractions(s3Client);
    }
}

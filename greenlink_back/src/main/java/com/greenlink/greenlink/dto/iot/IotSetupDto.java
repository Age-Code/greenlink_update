package com.greenlink.greenlink.dto.iot;

import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;

// IotSetupDto — API 요청/응답 DTO
public class IotSetupDto {

    // 재배 공간 생성 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrowSpaceCreateReqDto {

        @NotBlank(message = "재배 공간 이름은 필수입니다.")
        private String name;

        private String description;
    }

    // 재배 공간 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrowSpaceResDto {
        private Long growSpaceId;
        private String name;
        private String description;
        private Boolean active;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static GrowSpaceResDto from(GrowSpace growSpace) {
            return GrowSpaceResDto.builder()
                    .growSpaceId(growSpace.getId())
                    .name(growSpace.getName())
                    .description(growSpace.getDescription())
                    .active(growSpace.getActive())
                    .createdAt(growSpace.getCreatedAt())
                    .build();
        }
    }

    // 재배 공간에 식물 연결 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConnectPlantReqDto {

        @NotNull(message = "연결할 식물 ID는 필수입니다.")
        private Long userPlantId;
    }

    // 재배 공간-식물 연결 응답 DTO — grow_space_plant 응답
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrowSpacePlantResDto {
        private Long growSpacePlantId;

        private Long growSpaceId;
        private String growSpaceName;

        private Long userPlantId;
        private String plantNickname;
        private String plantName;

        private Boolean active;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static GrowSpacePlantResDto from(GrowSpacePlant growSpacePlant) {
            return GrowSpacePlantResDto.builder()
                    .growSpacePlantId(growSpacePlant.getId())

                    .growSpaceId(growSpacePlant.getGrowSpace().getId())
                    .growSpaceName(growSpacePlant.getGrowSpace().getName())

                    .userPlantId(growSpacePlant.getUserPlant().getId())
                    .plantNickname(growSpacePlant.getUserPlant().getNickname())
                    .plantName(growSpacePlant.getUserPlant().getPlant().getName())

                    .active(growSpacePlant.getActive())
                    .createdAt(growSpacePlant.getCreatedAt())
                    .build();
        }
    }

    // IoT 기기 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DeviceCreateReqDto {

        @NotBlank(message = "기기 이름은 필수입니다.")
        private String deviceName;

        @NotNull(message = "기기 타입은 필수입니다.")
        private DeviceType deviceType;

        @NotBlank(message = "기기 키는 필수입니다.")
        private String deviceKey;

        private Long growSpaceId;

        private Long userPlantId;
    }

    // IoT 기기 응답 DTO — RASPBERRY_PI / ESP32 공통 응답
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DeviceResDto {
        private Long deviceId;

        private String deviceName;
        private DeviceType deviceType;

        private Long growSpaceId;
        private String growSpaceName;

        private Long userPlantId;
        private String plantNickname;
        private String plantName;

        private Boolean active;
        private LocalDateTime lastConnectedAt;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DeviceResDto from(IotDevice device) {
            Long growSpaceId = device.getGrowSpace() == null
                    ? null
                    : device.getGrowSpace().getId();

            String growSpaceName = device.getGrowSpace() == null
                    ? null
                    : device.getGrowSpace().getName();

            Long userPlantId = device.getUserPlant() == null
                    ? null
                    : device.getUserPlant().getId();

            String plantNickname = device.getUserPlant() == null
                    ? null
                    : device.getUserPlant().getNickname();

            String plantName = device.getUserPlant() == null
                    ? null
                    : device.getUserPlant().getPlant().getName();

            return DeviceResDto.builder()
                    .deviceId(device.getId())
                    .deviceName(device.getDeviceName())
                    .deviceType(device.getDeviceType())

                    .growSpaceId(growSpaceId)
                    .growSpaceName(growSpaceName)

                    .userPlantId(userPlantId)
                    .plantNickname(plantNickname)
                    .plantName(plantName)

                    .active(device.getActive())
                    .lastConnectedAt(device.getLastConnectedAt())
                    .createdAt(device.getCreatedAt())
                    .build();
        }
    }

    // 펌프 채널 등록 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PumpChannelCreateReqDto {

        @NotNull(message = "재배 공간 ID는 필수입니다.")
        private Long growSpaceId;

        @NotNull(message = "식물 ID는 필수입니다.")
        private Long userPlantId;

        @NotNull(message = "라즈베리파이 기기 ID는 필수입니다.")
        private Long raspberryDeviceId;

        @NotBlank(message = "펌프 채널 이름은 필수입니다.")
        private String channelName;

        private Integer gpioPin;

        private Integer relayChannel;
    }

    // 펌프 채널 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PumpChannelResDto {
        private Long pumpChannelId;

        private Long growSpaceId;
        private String growSpaceName;

        private Long userPlantId;
        private String plantNickname;
        private String plantName;

        private Long raspberryDeviceId;
        private String raspberryDeviceName;

        private String channelName;
        private Integer gpioPin;
        private Integer relayChannel;

        private Boolean active;
        private LocalDateTime createdAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PumpChannelResDto from(PumpChannel pumpChannel) {
            return PumpChannelResDto.builder()
                    .pumpChannelId(pumpChannel.getId())

                    .growSpaceId(pumpChannel.getGrowSpace().getId())
                    .growSpaceName(pumpChannel.getGrowSpace().getName())

                    .userPlantId(pumpChannel.getUserPlant().getId())
                    .plantNickname(pumpChannel.getUserPlant().getNickname())
                    .plantName(pumpChannel.getUserPlant().getPlant().getName())

                    .raspberryDeviceId(pumpChannel.getRaspberryDevice().getId())
                    .raspberryDeviceName(pumpChannel.getRaspberryDevice().getDeviceName())

                    .channelName(pumpChannel.getChannelName())
                    .gpioPin(pumpChannel.getGpioPin())
                    .relayChannel(pumpChannel.getRelayChannel())

                    .active(pumpChannel.getActive())
                    .createdAt(pumpChannel.getCreatedAt())
                    .build();
        }
    }
}

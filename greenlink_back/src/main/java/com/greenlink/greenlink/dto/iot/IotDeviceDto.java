package com.greenlink.greenlink.dto.iot;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;

// IotDeviceDto — API 요청/응답 DTO
public class IotDeviceDto {

    // 라즈베리파이 환경 데이터 전송 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RaspberryEnvironmentReqDto {

        // DHT22 측정 범위
        @DecimalMin("-40.0")
        @DecimalMax("80.0")
        private Double temperature;

        @DecimalMin("0.0")
        @DecimalMax("100.0")
        private Double humidity;

        // BH1750 측정 범위(lux)
        @DecimalMin("0.0")
        @DecimalMax("65535.0")
        private Double light;

        // 라즈베리파이에서 측정한 시각. — null이면 서버에서 현재 시각으로 저장한다.
        private LocalDateTime measuredAt;
    }

    // 라즈베리파이 환경 데이터 저장 응답 DTO — 온도/습도/조도는 특정 식물 데이터가 아니라
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RaspberryEnvironmentResDto {
        private Long sensorDataId;

        private Long growSpaceId;
        private Long deviceId;

        private Double temperature;
        private Double humidity;
        private Double light;

        private LocalDateTime measuredAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static RaspberryEnvironmentResDto from(RaspberrySensorData data) {
            return RaspberryEnvironmentResDto.builder()
                    .sensorDataId(data.getId())
                    .growSpaceId(data.getGrowSpace().getId())
                    .deviceId(data.getIotDevice().getId())
                    .temperature(data.getTemperature())
                    .humidity(data.getHumidity())
                    .light(data.getLight())
                    .measuredAt(data.getMeasuredAt())
                    .build();
        }
    }

    // ESP 토양수분 데이터 전송 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EspSoilMoistureReqDto {

        // ESP32 12bit ADC 범위
        @Min(0)
        @Max(4095)
        private Integer soilMoistureRaw;

        // 자동 급수 판단에 쓰이므로 누락·범위 밖 값은 저장 전에 거부한다.
        @NotNull
        @DecimalMin("0.0")
        @DecimalMax("100.0")
        private Double soilMoisturePercent;

        // ESP에서 측정한 시각. — null이면 서버에서 현재 시각으로 저장한다.
        private LocalDateTime measuredAt;
    }

    // ESP 토양수분 데이터 저장 응답 DTO — 토양수분은 식물별 데이터이므로 userPlantId가 포함된다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EspSoilMoistureResDto {
        private Long sensorDataId;

        private Long growSpaceId;
        private Long userPlantId;
        private Long deviceId;

        private Integer soilMoistureRaw;
        private Double soilMoisturePercent;

        private LocalDateTime measuredAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static EspSoilMoistureResDto from(EspSensorData data) {
            Long growSpaceId = data.getGrowSpace() == null
                    ? null
                    : data.getGrowSpace().getId();

            return EspSoilMoistureResDto.builder()
                    .sensorDataId(data.getId())
                    .growSpaceId(growSpaceId)
                    .userPlantId(data.getUserPlant().getId())
                    .deviceId(data.getIotDevice().getId())
                    .soilMoistureRaw(data.getSoilMoistureRaw())
                    .soilMoisturePercent(data.getSoilMoisturePercent())
                    .measuredAt(data.getMeasuredAt())
                    .build();
        }
    }

    // 라즈베리파이가 조회하는 대기 명령 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PendingCommandResDto {
        private Long commandId;

        private CommandType commandType;

        private Integer durationSeconds;

        private Long userPlantId;

        private PumpChannelCommandDto pumpChannel;

        private LocalDateTime requestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PendingCommandResDto from(DeviceCommand command) {
            return PendingCommandResDto.builder()
                    .commandId(command.getId())
                    .commandType(command.getCommandType())
                    .durationSeconds(command.getDurationSeconds())
                    .userPlantId(command.getUserPlant().getId())
                    .pumpChannel(PumpChannelCommandDto.from(command.getPumpChannel()))
                    .requestedAt(command.getRequestedAt())
                    .build();
        }
    }

    // 라즈베리파이 명령 처리용 펌프 채널 DTO — 앱 사용자에게 보여주는 정보가 아니라,
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PumpChannelCommandDto {
        private Long pumpChannelId;

        private Integer gpioPin;

        private Integer relayChannel;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PumpChannelCommandDto from(PumpChannel pumpChannel) {
            if (pumpChannel == null) {
                return null;
            }

            return PumpChannelCommandDto.builder()
                    .pumpChannelId(pumpChannel.getId())
                    .gpioPin(pumpChannel.getGpioPin())
                    .relayChannel(pumpChannel.getRelayChannel())
                    .build();
        }
    }

    // 명령 처리 시작 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CommandProcessingResDto {
        private Long commandId;

        private CommandStatus commandStatus;

        private LocalDateTime processedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static CommandProcessingResDto from(DeviceCommand command) {
            return CommandProcessingResDto.builder()
                    .commandId(command.getId())
                    .commandStatus(command.getCommandStatus())
                    .processedAt(command.getProcessedAt())
                    .build();
        }
    }

    // 명령 처리 완료 요청 DTO
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CommandCompleteReqDto {

        @NotNull(message = "명령 처리 성공 여부는 필수입니다.")
        private Boolean success;

        private String resultMessage;
    }

    // 명령 처리 완료 응답 DTO — success == true → commandStatus = SUCCESS
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CommandCompleteResDto {
        private Long commandId;

        private CommandStatus commandStatus;

        private String resultMessage;

        private LocalDateTime completedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static CommandCompleteResDto from(DeviceCommand command) {
            return CommandCompleteResDto.builder()
                    .commandId(command.getId())
                    .commandStatus(command.getCommandStatus())
                    .resultMessage(command.getResultMessage())
                    .completedAt(command.getCompletedAt())
                    .build();
        }
    }

    // 라즈베리파이 식물 이미지 업로드 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PlantImageUploadResDto {
        private Long plantImageId;

        private Long growSpaceId;
        private Long userPlantId;
        private Long deviceId;

        private String imageUrl;
        private String originalFilename;

        private LocalDateTime capturedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PlantImageUploadResDto from(PlantImage plantImage) {
            Long userPlantId = plantImage.getUserPlant() == null
                    ? null
                    : plantImage.getUserPlant().getId();

            return PlantImageUploadResDto.builder()
                    .plantImageId(plantImage.getId())
                    .growSpaceId(plantImage.getGrowSpace().getId())
                    .userPlantId(userPlantId)
                    .deviceId(plantImage.getIotDevice().getId())
                    .imageUrl(plantImage.getImageUrl())
                    .originalFilename(plantImage.getOriginalFilename())
                    .capturedAt(plantImage.getCapturedAt())
                    .build();
        }
    }
}

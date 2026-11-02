package com.greenlink.greenlink.dto.iot;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

// IotAppDto — API 요청/응답 DTO
public class IotAppDto {

    // 내 식물 IoT 최신 상태 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class IotLatestResDto {
        private Long userPlantId;
        private GrowSpaceSimpleDto growSpace;
        private EnvironmentDto environment;
        private SoilDto soil;
        private PlantImageDto latestImage;
        private WateringDto watering;

        // 마지막으로 성공한 조명 명령 기준 상태 — 조명 명령 기록이 없으면 null
        private LightStateDto light;

        // 최근 장치 명령과 실행 결과 (최신순)
        private List<CommandSummaryDto> recentCommands;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static IotLatestResDto of(
                Long userPlantId,
                GrowSpace growSpace,
                RaspberrySensorData raspberrySensorData,
                EspSensorData espSensorData,
                PlantImage latestImage,
                WateringDto watering,
                DeviceCommand lastLightCommand,
                List<DeviceCommand> recentCommands
        ) {
            return IotLatestResDto.builder()
                    .userPlantId(userPlantId)
                    .growSpace(GrowSpaceSimpleDto.from(growSpace))
                    .environment(EnvironmentDto.from(raspberrySensorData))
                    .soil(SoilDto.from(espSensorData))
                    .latestImage(PlantImageDto.from(latestImage))
                    .watering(watering)
                    .light(LightStateDto.from(lastLightCommand))
                    .recentCommands(recentCommands.stream().map(CommandSummaryDto::from).toList())
                    .build();
        }
    }

    // 조명 상태 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LightStateDto {
        private boolean on;
        private LocalDateTime changedAt;

        public static LightStateDto from(DeviceCommand command) {
            if (command == null) {
                return null;
            }

            return LightStateDto.builder()
                    .on(command.getCommandType() == CommandType.LIGHT_ON)
                    .changedAt(command.getCompletedAt())
                    .build();
        }
    }

    // 명령 이력 요약 DTO — 앱에서 "물 주기 완료/실패" 등을 보여주기 위한 최소 정보
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CommandSummaryDto {
        private Long commandId;
        private CommandType commandType;
        private CommandStatus commandStatus;
        private LocalDateTime requestedAt;
        private LocalDateTime completedAt;
        private String resultMessage;

        public static CommandSummaryDto from(DeviceCommand command) {
            return CommandSummaryDto.builder()
                    .commandId(command.getId())
                    .commandType(command.getCommandType())
                    .commandStatus(command.getCommandStatus())
                    .requestedAt(command.getRequestedAt())
                    .completedAt(command.getCompletedAt())
                    .resultMessage(command.getResultMessage())
                    .build();
        }
    }

    // 센서 기록 응답 DTO — 앱 그래프용 시계열 (측정 시각 오름차순)
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SensorHistoryResDto {
        private Long userPlantId;
        private int hours;
        private List<SoilPointDto> soil;
        private List<EnvironmentPointDto> environment;
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SoilPointDto {
        private LocalDateTime measuredAt;
        private Double soilMoisturePercent;

        public static SoilPointDto from(EspSensorData data) {
            return SoilPointDto.builder()
                    .measuredAt(data.getMeasuredAt())
                    .soilMoisturePercent(data.getSoilMoisturePercent())
                    .build();
        }
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EnvironmentPointDto {
        private LocalDateTime measuredAt;
        private Double temperature;
        private Double humidity;
        private Double light;

        public static EnvironmentPointDto from(RaspberrySensorData data) {
            return EnvironmentPointDto.builder()
                    .measuredAt(data.getMeasuredAt())
                    .temperature(data.getTemperature())
                    .humidity(data.getHumidity())
                    .light(data.getLight())
                    .build();
        }
    }

    // 급수 가능 여부 DTO — 앱이 자체 기준으로 판단하지 않도록 서버 판정 결과를 전달한다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WateringDto {

        // 현재 급수 요청이 허용되는지 여부
        private boolean canWater;

        // 차단된 경우 사용자에게 보여줄 사유
        private String blockReason;

        // 물 부족 안내 기준 — 자동 급수 임계치와 같은 값이다.
        private Double shortageThresholdPercent;

        // 급수 허용 상태 생성
        public static WateringDto allowed(Double shortageThresholdPercent) {
            return WateringDto.builder()
                    .canWater(true)
                    .shortageThresholdPercent(shortageThresholdPercent)
                    .build();
        }

        // 급수 차단 상태 생성
        public static WateringDto blocked(
                Double shortageThresholdPercent,
                String blockReason
        ) {
            return WateringDto.builder()
                    .canWater(false)
                    .blockReason(blockReason)
                    .shortageThresholdPercent(shortageThresholdPercent)
                    .build();
        }
    }

    // 앱 화면에 표시할 간단한 재배 공간 정보 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrowSpaceSimpleDto {
        private Long growSpaceId;
        private String name;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static GrowSpaceSimpleDto from(GrowSpace growSpace) {
            if (growSpace == null) {
                return null;
            }

            return GrowSpaceSimpleDto.builder()
                    .growSpaceId(growSpace.getId())
                    .name(growSpace.getName())
                    .build();
        }
    }

    // 라즈베리파이 환경 센서 데이터 DTO — 온도, 습도, 조도는 특정 식물 하나의 값이 아니라
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EnvironmentDto {
        private Long sensorDataId;
        private Double temperature;
        private Double humidity;
        private Double light;
        private LocalDateTime measuredAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static EnvironmentDto from(RaspberrySensorData data) {
            if (data == null) {
                return null;
            }

            return EnvironmentDto.builder()
                    .sensorDataId(data.getId())
                    .temperature(data.getTemperature())
                    .humidity(data.getHumidity())
                    .light(data.getLight())
                    .measuredAt(data.getMeasuredAt())
                    .build();
        }
    }

    // ESP 토양수분 데이터 DTO — 토양수분은 식물마다 다르므로 userPlant 기준 데이터다.
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SoilDto {
        private Long sensorDataId;
        private Integer soilMoistureRaw;
        private Double soilMoisturePercent;
        private LocalDateTime measuredAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static SoilDto from(EspSensorData data) {
            if (data == null) {
                return null;
            }

            return SoilDto.builder()
                    .sensorDataId(data.getId())
                    .soilMoistureRaw(data.getSoilMoistureRaw())
                    .soilMoisturePercent(data.getSoilMoisturePercent())
                    .measuredAt(data.getMeasuredAt())
                    .build();
        }
    }

    // PlantImageDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PlantImageDto {
        private Long plantImageId;

        // 매일 고정 시각에 카메라 영상에서 캡처한 사진 — 서버 상대 경로("/images/...")
        private String imageUrl;

        private LocalDateTime capturedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static PlantImageDto from(PlantImage plantImage) {
            if (plantImage == null) {
                return null;
            }

            return PlantImageDto.builder()
                    .plantImageId(plantImage.getId())
                    .imageUrl(plantImage.getImageUrl())
                    .capturedAt(plantImage.getCapturedAt())
                    .build();
        }
    }

    // 물 주기 명령 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WaterCommandResDto {
        private Long commandId;
        private Long userPlantId;
        private Long growSpaceId;
        private Long deviceId;
        private Long pumpChannelId;
        private CommandType commandType;
        private CommandStatus commandStatus;
        private Integer durationSeconds;
        private LocalDateTime requestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static WaterCommandResDto from(DeviceCommand command) {
            Long pumpChannelId = command.getPumpChannel() == null
                    ? null
                    : command.getPumpChannel().getId();

            return WaterCommandResDto.builder()
                    .commandId(command.getId())
                    .userPlantId(command.getUserPlant().getId())
                    .growSpaceId(command.getGrowSpace().getId())
                    .deviceId(command.getIotDevice().getId())
                    .pumpChannelId(pumpChannelId)
                    .commandType(command.getCommandType())
                    .commandStatus(command.getCommandStatus())
                    .durationSeconds(command.getDurationSeconds())
                    .requestedAt(command.getRequestedAt())
                    .build();
        }
    }

    // 조명 명령 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LightCommandResDto {
        private Long commandId;
        private Long userPlantId;
        private Long growSpaceId;
        private Long deviceId;
        private CommandType commandType;
        private CommandStatus commandStatus;
        private LocalDateTime requestedAt;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static LightCommandResDto from(DeviceCommand command) {
            return LightCommandResDto.builder()
                    .commandId(command.getId())
                    .userPlantId(command.getUserPlant().getId())
                    .growSpaceId(command.getGrowSpace().getId())
                    .deviceId(command.getIotDevice().getId())
                    .commandType(command.getCommandType())
                    .commandStatus(command.getCommandStatus())
                    .requestedAt(command.getRequestedAt())
                    .build();
        }
    }

    // 공통 장치 명령 응답 DTO
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DeviceCommandResDto {
        private Long commandId;
        private Long userPlantId;
        private Long growSpaceId;
        private Long deviceId;
        private Long pumpChannelId;
        private CommandType commandType;
        private CommandStatus commandStatus;
        private Integer durationSeconds;
        private LocalDateTime requestedAt;
        private String target;
        private Boolean alreadyPending;
        private String duplicateReason;
        private List<String> refreshTargets;
        private List<String> excludedTargets;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static DeviceCommandResDto fromSensorRefresh(DeviceCommand command) {
            Long pumpChannelId = command.getPumpChannel() == null
                    ? null
                    : command.getPumpChannel().getId();

            return DeviceCommandResDto.builder()
                    .commandId(command.getId())
                    .userPlantId(command.getUserPlant().getId())
                    .growSpaceId(command.getGrowSpace().getId())
                    .deviceId(command.getIotDevice().getId())
                    .pumpChannelId(pumpChannelId)
                    .commandType(command.getCommandType())
                    .commandStatus(command.getCommandStatus())
                    .durationSeconds(command.getDurationSeconds())
                    .requestedAt(command.getRequestedAt())
                    .target("RASPBERRY_ENVIRONMENT")
                    .alreadyPending(false)
                    .duplicateReason(null)
                    .refreshTargets(List.of("temperature", "humidity", "light"))
                    .excludedTargets(List.of("soilMoisture"))
                    .build();
        }
    }
}

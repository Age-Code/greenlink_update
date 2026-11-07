package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.EspSensorData;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.iot.RaspberrySensorData;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.dto.iot.IotDeviceDto;
import com.greenlink.greenlink.repository.EspSensorDataRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.PlantImageRepository;
import com.greenlink.greenlink.repository.RaspberrySensorDataRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;

// IotDeviceDataService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IotDeviceDataService {

    private final IotDeviceRepository iotDeviceRepository;
    private final RaspberrySensorDataRepository raspberrySensorDataRepository;
    private final EspSensorDataRepository espSensorDataRepository;
    private final PlantImageRepository plantImageRepository;
    private final UserPlantRepository userPlantRepository;
    private final GrowSpacePlantRepository growSpacePlantRepository;
    private final ImageStorageService imageStorageService;
    private final AutomationService automationService;

    // save Raspberry Environment 저장
    @Transactional
    public IotDeviceDto.RaspberryEnvironmentResDto saveRaspberryEnvironment(
            String deviceKey,
            IotDeviceDto.RaspberryEnvironmentReqDto request
    ) {
        IotDevice raspberryDevice = findActiveDeviceByKey(deviceKey);

        validateRaspberryDevice(raspberryDevice);

        GrowSpace growSpace = raspberryDevice.getGrowSpace();

        if (growSpace == null) {
            throw new IllegalStateException("라즈베리파이에 연결된 재배 공간이 없습니다.");
        }

        RaspberrySensorData sensorData = RaspberrySensorData.create(
                growSpace,
                raspberryDevice,
                request.getTemperature(),
                request.getHumidity(),
                request.getLight(),
                request.getMeasuredAt()
        );

        RaspberrySensorData savedSensorData =
                raspberrySensorDataRepository.save(sensorData);

        raspberryDevice.updateLastConnectedAt();

        automationService.evaluateAutoLight(savedSensorData);

        return IotDeviceDto.RaspberryEnvironmentResDto.from(savedSensorData);
    }

    // save Esp Soil Moisture 저장
    @Transactional
    public IotDeviceDto.EspSoilMoistureResDto saveEspSoilMoisture(
            String deviceKey,
            IotDeviceDto.EspSoilMoistureReqDto request
    ) {
        IotDevice espDevice = findActiveDeviceByKey(deviceKey);

        validateEspDevice(espDevice);

        UserPlant userPlant = espDevice.getUserPlant();

        if (userPlant == null) {
            throw new IllegalStateException("ESP32에 연결된 식물이 없습니다.");
        }

        EspSensorData sensorData = EspSensorData.create(
                espDevice.getGrowSpace(),
                userPlant,
                espDevice,
                request.getSoilMoistureRaw(),
                request.getSoilMoisturePercent(),
                request.getMeasuredAt()
        );

        EspSensorData savedSensorData =
                espSensorDataRepository.save(sensorData);

        espDevice.updateLastConnectedAt();

        automationService.evaluateAutoWater(savedSensorData);

        return IotDeviceDto.EspSoilMoistureResDto.from(savedSensorData);
    }

    // save Plant Image 저장
    @Transactional
    public IotDeviceDto.PlantImageUploadResDto savePlantImage(
            String deviceKey,
            MultipartFile file,
            Long userPlantId,
            LocalDateTime capturedAt
    ) {
        IotDevice raspberryDevice = findActiveDeviceByKey(deviceKey);

        validateRaspberryDevice(raspberryDevice);

        GrowSpace growSpace = raspberryDevice.getGrowSpace();

        if (growSpace == null) {
            throw new IllegalStateException("라즈베리파이에 연결된 재배 공간이 없습니다.");
        }

        UserPlant userPlant = resolveImagePlant(growSpace, userPlantId);

        String imageUrl = imageStorageService.storeUserPlantImage(
                file,
                userPlant == null ? null : userPlant.getId()
        );
        String originalFilename = file.getOriginalFilename();

        PlantImage plantImage = PlantImage.create(
                growSpace,
                userPlant,
                raspberryDevice,
                imageUrl,
                originalFilename,
                capturedAt
        );

        PlantImage savedPlantImage = plantImageRepository.save(plantImage);

        raspberryDevice.updateLastConnectedAt();

        return IotDeviceDto.PlantImageUploadResDto.from(savedPlantImage);
    }

    // 사진을 붙일 식물 결정
    // 1) Pi가 보낸 userPlantId가 이 재배 공간에 연결돼 있으면 그 식물
    // 2) 아니면 재배 공간에 연결된 식물이 하나뿐일 때 그 식물 — 재배기 1대 = 식물 1개 운영에서
    //    새 식물을 심어도 Pi 설정(GREENLINK_USER_PLANT_ID)을 고치지 않아도 되게 한다.
    // 3) 그래도 정할 수 없으면 userPlantId 없이 온 경우 공간 공용 사진, 잘못된 ID면 거부
    private UserPlant resolveImagePlant(GrowSpace growSpace, Long userPlantId) {
        if (userPlantId != null) {
            UserPlant requested = userPlantRepository.findByIdAndDeletedFalse(userPlantId).orElse(null);

            if (requested != null && growSpacePlantRepository.existsByGrowSpaceAndUserPlantAndDeletedFalse(
                    growSpace,
                    requested
            )) {
                return requested;
            }
        }

        List<GrowSpacePlant> connected =
                growSpacePlantRepository.findAllByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace);

        if (connected.size() == 1) {
            return connected.get(0).getUserPlant();
        }

        if (userPlantId != null) {
            throw new IllegalStateException("해당 식물은 라즈베리파이의 재배 공간에 연결되어 있지 않습니다.");
        }

        return null;
    }

    // find Active Device By Key 조회 — 없으면 예외 또는 Optional 반환
    private IotDevice findActiveDeviceByKey(String deviceKey) {
        if (deviceKey == null || deviceKey.isBlank()) {
            throw new IllegalArgumentException("X-DEVICE-KEY가 필요합니다.");
        }

        return iotDeviceRepository.findByDeviceKeyAndActiveTrueAndDeletedFalse(deviceKey)
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않았거나 비활성화된 기기입니다."));
    }

    // validate Raspberry Device 검증
    private void validateRaspberryDevice(IotDevice device) {
        if (!device.isRaspberryPi()) {
            throw new IllegalStateException("라즈베리파이 기기만 환경 데이터 또는 이미지를 전송할 수 있습니다.");
        }
    }

    // validate Esp Device 검증
    private void validateEspDevice(IotDevice device) {
        if (!device.isEsp32()) {
            throw new IllegalStateException("ESP32 기기만 토양수분 데이터를 전송할 수 있습니다.");
        }
    }
}

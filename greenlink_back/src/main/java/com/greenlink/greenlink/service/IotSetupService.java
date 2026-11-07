package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.iot.IotSetupDto;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.GrowSpaceRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.PumpChannelRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// IotSetupService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IotSetupService {

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;

    private final GrowSpaceRepository growSpaceRepository;
    private final GrowSpacePlantRepository growSpacePlantRepository;
    private final IotDeviceRepository iotDeviceRepository;
    private final PumpChannelRepository pumpChannelRepository;
    private final GrowerAssignmentService growerAssignmentService;

    // 재배 공간 생성
    @Transactional
    public IotSetupDto.GrowSpaceResDto createGrowSpace(
            IotSetupDto.GrowSpaceCreateReqDto request
    ) {
        if (growSpaceRepository.existsByNameAndDeletedFalse(request.getName())) {
            throw new IllegalArgumentException("이미 등록된 재배 공간 이름입니다.");
        }

        GrowSpace growSpace = GrowSpace.create(
                request.getName(),
                request.getDescription()
        );

        GrowSpace savedGrowSpace = growSpaceRepository.save(growSpace);

        return IotSetupDto.GrowSpaceResDto.from(savedGrowSpace);
    }

    // 재배 공간 목록 조회
    public List<IotSetupDto.GrowSpaceResDto> getGrowSpaces() {
        return growSpaceRepository.findAllByDeletedFalse()
                .stream()
                .map(IotSetupDto.GrowSpaceResDto::from)
                .toList();
    }

    // 재배 공간에 식물 연결 — grow_space에는 user_id가 없으므로,
    @Transactional
    public IotSetupDto.GrowSpacePlantResDto connectPlantToGrowSpace(
            Long userId,
            Long growSpaceId,
            IotSetupDto.ConnectPlantReqDto request
    ) {
        findActiveUser(userId);

        GrowSpace growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(growSpaceId)
                .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

        // 구성 API는 ADMIN 전용이므로 호출자 소유가 아닌 사용자 식물도 연결할 수 있어야 한다.
        UserPlant userPlant = userPlantRepository.findByIdAndDeletedFalse(request.getUserPlantId())
                .orElseThrow(() -> new IllegalArgumentException("연결할 식물을 찾을 수 없습니다."));

        if (growSpacePlantRepository.existsByUserPlantAndDeletedFalse(userPlant)) {
            throw new IllegalStateException("이미 재배 공간에 연결된 식물입니다.");
        }

        GrowSpacePlant growSpacePlant = GrowSpacePlant.connect(growSpace, userPlant);

        GrowSpacePlant savedGrowSpacePlant = growSpacePlantRepository.save(growSpacePlant);

        return IotSetupDto.GrowSpacePlantResDto.from(savedGrowSpacePlant);
    }

    // 재배기 담당 식물 교체 — 재배기 1대 = 식물 1개 기준
    @Transactional
    public IotSetupDto.GrowSpacePlantResDto replantGrowSpace(
            Long growSpaceId,
            IotSetupDto.ConnectPlantReqDto request
    ) {
        GrowSpace growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(growSpaceId)
                .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

        UserPlant userPlant = userPlantRepository.findByIdAndDeletedFalse(request.getUserPlantId())
                .orElseThrow(() -> new IllegalArgumentException("연결할 식물을 찾을 수 없습니다."));

        GrowSpacePlant connection = growerAssignmentService.moveGrowSpaceToPlant(growSpace, userPlant);

        return IotSetupDto.GrowSpacePlantResDto.from(connection);
    }

    // 특정 재배 공간에 연결된 식물 목록 조회
    public List<IotSetupDto.GrowSpacePlantResDto> getGrowSpacePlants(
            Long growSpaceId
    ) {
        GrowSpace growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(growSpaceId)
                .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

        return growSpacePlantRepository.findAllByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace)
                .stream()
                .map(IotSetupDto.GrowSpacePlantResDto::from)
                .toList();
    }

    // IoT 기기 등록 — Pi/ESP 유형별 Entity 생성
    @Transactional
    public IotSetupDto.DeviceResDto createDevice(
            Long userId,
            IotSetupDto.DeviceCreateReqDto request
    ) {
        User user = findActiveUser(userId);

        if (iotDeviceRepository.existsByDeviceKeyAndDeletedFalse(request.getDeviceKey())) {
            throw new IllegalArgumentException("이미 등록된 deviceKey입니다.");
        }

        IotDevice device;

        if (request.getDeviceType() == DeviceType.RASPBERRY_PI) {
            device = createRaspberryDevice(request);
        } else if (request.getDeviceType() == DeviceType.ESP32) {
            device = createEspDevice(user, request);
        } else {
            throw new IllegalArgumentException("지원하지 않는 기기 타입입니다.");
        }

        IotDevice savedDevice = iotDeviceRepository.save(device);

        return IotSetupDto.DeviceResDto.from(savedDevice);
    }

    // IoT 기기 목록 조회 — 현재는 전체 기기 조회.
    public List<IotSetupDto.DeviceResDto> getDevices() {
        return iotDeviceRepository.findAllByDeletedFalse()
                .stream()
                .map(IotSetupDto.DeviceResDto::from)
                .toList();
    }

    // 펌프 채널 등록 — 한 식물당 펌프 채널 1개만 연결한다.
    @Transactional
    public IotSetupDto.PumpChannelResDto createPumpChannel(
            Long userId,
            IotSetupDto.PumpChannelCreateReqDto request
    ) {
        findActiveUser(userId);

        GrowSpace growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(
                        request.getGrowSpaceId()
                )
                .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

        UserPlant userPlant = userPlantRepository.findByIdAndDeletedFalse(request.getUserPlantId())
                .orElseThrow(() -> new IllegalArgumentException("펌프를 연결할 식물을 찾을 수 없습니다."));

        validateUserPlantConnectedToGrowSpace(growSpace, userPlant);

        IotDevice raspberryDevice = iotDeviceRepository.findByIdAndActiveTrueAndDeletedFalse(
                        request.getRaspberryDeviceId()
                )
                .orElseThrow(() -> new IllegalArgumentException("라즈베리파이 기기를 찾을 수 없습니다."));

        validateRaspberryDeviceInGrowSpace(raspberryDevice, growSpace);

        if (pumpChannelRepository.existsByUserPlantAndDeletedFalse(userPlant)) {
            throw new IllegalStateException("이미 펌프 채널이 연결된 식물입니다.");
        }

        PumpChannel pumpChannel = PumpChannel.create(
                growSpace,
                userPlant,
                raspberryDevice,
                request.getChannelName(),
                request.getGpioPin(),
                request.getRelayChannel()
        );

        PumpChannel savedPumpChannel = pumpChannelRepository.save(pumpChannel);

        return IotSetupDto.PumpChannelResDto.from(savedPumpChannel);
    }

    // 펌프 채널 목록 조회
    public List<IotSetupDto.PumpChannelResDto> getPumpChannels() {
        return pumpChannelRepository.findAllByDeletedFalse()
                .stream()
                .map(IotSetupDto.PumpChannelResDto::from)
                .toList();
    }

    // create Raspberry Device 생성
    private IotDevice createRaspberryDevice(
            IotSetupDto.DeviceCreateReqDto request
    ) {
        if (request.getGrowSpaceId() == null) {
            throw new IllegalArgumentException("라즈베리파이는 growSpaceId가 필요합니다.");
        }

        if (request.getUserPlantId() != null) {
            throw new IllegalArgumentException("라즈베리파이는 특정 식물에 직접 연결할 수 없습니다.");
        }

        GrowSpace growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(
                        request.getGrowSpaceId()
                )
                .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

        return IotDevice.createRaspberryPi(
                growSpace,
                request.getDeviceName(),
                request.getDeviceKey()
        );
    }

    // create Esp Device 생성
    private IotDevice createEspDevice(
            User user,
            IotSetupDto.DeviceCreateReqDto request
    ) {
        if (request.getUserPlantId() == null) {
            throw new IllegalArgumentException("ESP32는 userPlantId가 필요합니다.");
        }

        UserPlant userPlant = userPlantRepository.findByIdAndDeletedFalse(request.getUserPlantId())
                .orElseThrow(() -> new IllegalArgumentException("ESP32를 연결할 식물을 찾을 수 없습니다."));

        GrowSpace growSpace = null;

        if (request.getGrowSpaceId() != null) {
            growSpace = growSpaceRepository.findByIdAndActiveTrueAndDeletedFalse(
                            request.getGrowSpaceId()
                    )
                    .orElseThrow(() -> new IllegalArgumentException("재배 공간을 찾을 수 없습니다."));

            validateUserPlantConnectedToGrowSpace(growSpace, userPlant);
        } else {
            // growSpace 없는 ESP는 자동 급수가 항상 건너뛰어지므로 식물의 연결 공간을 사용한다.
            growSpace = growSpacePlantRepository.findByUserPlantAndActiveTrueAndDeletedFalse(userPlant)
                    .map(GrowSpacePlant::getGrowSpace)
                    .orElseThrow(() -> new IllegalStateException("ESP32를 등록하기 전에 식물을 재배 공간에 연결해야 합니다."));
        }

        return IotDevice.createEsp32(
                growSpace,
                userPlant,
                request.getDeviceName(),
                request.getDeviceKey()
        );
    }

    // validate User Plant Connected To Grow Space 검증
    private void validateUserPlantConnectedToGrowSpace(
            GrowSpace growSpace,
            UserPlant userPlant
    ) {
        boolean connected = growSpacePlantRepository.existsByGrowSpaceAndUserPlantAndDeletedFalse(
                growSpace,
                userPlant
        );

        if (!connected) {
            throw new IllegalStateException("해당 식물은 이 재배 공간에 연결되어 있지 않습니다.");
        }
    }

    // validate Raspberry Device In Grow Space 검증
    private void validateRaspberryDeviceInGrowSpace(
            IotDevice raspberryDevice,
            GrowSpace growSpace
    ) {
        if (!raspberryDevice.isRaspberryPi()) {
            throw new IllegalStateException("펌프 채널은 라즈베리파이 기기에만 연결할 수 있습니다.");
        }

        if (raspberryDevice.getGrowSpace() == null ||
                !raspberryDevice.getGrowSpace().getId().equals(growSpace.getId())) {
            throw new IllegalStateException("라즈베리파이 기기가 해당 재배 공간에 연결되어 있지 않습니다.");
        }
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

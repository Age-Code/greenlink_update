package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.CommandType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.quest.TargetType;
import com.greenlink.greenlink.dto.iot.IotDeviceDto;
import com.greenlink.greenlink.repository.AutomationLogRepository;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

// IoT 명령 서비스 — Pi polling용 명령 조회, 상태 전환, WATERING 퀘스트 연결
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IotCommandService {

    private static final String STALE_RESULT_MESSAGE = "장치가 제때 가져가지 않아 자동으로 취소되었습니다.";
    private static final long CONNECTED_AT_TOUCH_MINUTES = 1;

    private final IotDeviceRepository iotDeviceRepository;
    private final DeviceCommandRepository deviceCommandRepository;
    private final QuestProgressService questProgressService;
    private final AutomationLogRepository automationLogRepository;

    // 라즈베리파이 대기 명령 조회 — X-DEVICE-KEY로 Pi 검증
    // Pi가 오래 꺼져 있다 돌아와도 지난 급수·조명 명령을 몰아서 실행하지 않도록
    // 방치 기준(5분)을 넘긴 PENDING 명령은 내려주지 않고 CANCELLED로 정리한다.
    @Transactional
    public List<IotDeviceDto.PendingCommandResDto> getPendingCommands(
            String deviceKey
    ) {
        IotDevice raspberryDevice = findActiveDeviceByKey(deviceKey);

        validateRaspberryDevice(raspberryDevice);

        LocalDateTime now = LocalDateTime.now();
        touchLastConnectedAt(raspberryDevice, now);

        List<DeviceCommand> deliverable = new ArrayList<>();

        for (DeviceCommand command : deviceCommandRepository
                .findAllByIotDeviceAndCommandStatusAndDeletedFalseOrderByRequestedAtAsc(
                        raspberryDevice,
                        CommandStatus.PENDING
                )) {
            if (command.isStale(now)) {
                command.cancel(STALE_RESULT_MESSAGE);
                continue;
            }

            deliverable.add(command);
        }

        return deliverable.stream()
                .map(IotDeviceDto.PendingCommandResDto::from)
                .toList();
    }

    // 명령 polling도 장치 접속으로 본다. — 3초마다 쓰지 않도록 1분 간격으로만 갱신한다.
    private void touchLastConnectedAt(IotDevice device, LocalDateTime now) {
        LocalDateTime last = device.getLastConnectedAt();

        if (last == null || last.isBefore(now.minusMinutes(CONNECTED_AT_TOUCH_MINUTES))) {
            device.updateLastConnectedAt();
        }
    }

    // 명령 처리 시작 — PENDING → PROCESSING
    @Transactional
    public IotDeviceDto.CommandProcessingResDto markCommandProcessing(
            String deviceKey,
            Long commandId
    ) {
        IotDevice raspberryDevice = findActiveDeviceByKey(deviceKey);

        validateRaspberryDevice(raspberryDevice);

        DeviceCommand command = findCommandForDevice(commandId, raspberryDevice);

        command.markProcessing();

        return IotDeviceDto.CommandProcessingResDto.from(command);
    }

    // 명령 처리 완료 — success == true → SUCCESS
    @Transactional
    public IotDeviceDto.CommandCompleteResDto completeCommand(
            String deviceKey,
            Long commandId,
            IotDeviceDto.CommandCompleteReqDto request
    ) {
        IotDevice raspberryDevice = findActiveDeviceByKey(deviceKey);

        validateRaspberryDevice(raspberryDevice);

        DeviceCommand command = findCommandForDevice(commandId, raspberryDevice);

        String resultMessage = request.getResultMessage();

        if (request.getSuccess()) {
            command.completeSuccess(
                    resultMessage == null || resultMessage.isBlank()
                            ? "명령 처리 성공"
                            : resultMessage
            );
            increaseWateringQuestProgressIfNeeded(command);
        } else {
            command.completeFailed(
                    resultMessage == null || resultMessage.isBlank()
                            ? "명령 처리 실패"
                            : resultMessage
            );
        }

        return IotDeviceDto.CommandCompleteResDto.from(command);
    }

    // increase Watering Quest Progress If Needed 처리
    private void increaseWateringQuestProgressIfNeeded(DeviceCommand command) {
        if (command.getCommandType() != CommandType.WATER) {
            return;
        }

        // 자동 급수는 사용자가 한 행동이 아니므로 "물 주기" 퀘스트에 넣지 않는다.
        if (automationLogRepository.existsByCommandAndDeletedFalse(command)) {
            return;
        }

        questProgressService.increaseProgress(
                command.getUserPlant().getUser(),
                TargetType.WATERING,
                1
        );
    }

    // find Command For Device 조회 — 없으면 예외 또는 Optional 반환
    private DeviceCommand findCommandForDevice(
            Long commandId,
            IotDevice raspberryDevice
    ) {
        DeviceCommand command = deviceCommandRepository.findByIdAndDeletedFalse(commandId)
                .orElseThrow(() -> new IllegalArgumentException("명령을 찾을 수 없습니다."));

        if (!command.getIotDevice().getId().equals(raspberryDevice.getId())) {
            throw new IllegalStateException("해당 기기가 처리할 수 있는 명령이 아닙니다.");
        }

        return command;
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
            throw new IllegalStateException("라즈베리파이 기기만 명령을 처리할 수 있습니다.");
        }
    }
}

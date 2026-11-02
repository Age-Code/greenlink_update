package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.iot.CommandStatus;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.dto.AdminDto;
import com.greenlink.greenlink.repository.DeviceCommandRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// 관리자 대시보드 — 사용자/식물/장치/명령 운영 현황 집계
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminDashboardService {

    // 센서 업로드 주기(10분)의 3배 동안 연결 기록이 없으면 오프라인으로 본다.
    private static final long DEVICE_OFFLINE_MINUTES = 30;
    private static final int RECENT_COMMAND_COUNT = 15;

    private final UserRepository userRepository;
    private final UserPlantRepository userPlantRepository;
    private final IotDeviceRepository iotDeviceRepository;
    private final DeviceCommandRepository deviceCommandRepository;

    public AdminDto.DashboardDto getDashboard() {
        LocalDateTime now = LocalDateTime.now();

        List<AdminDto.DeviceStatusDto> devices = iotDeviceRepository.findAllByDeletedFalse()
                .stream()
                .map(device -> AdminDto.DeviceStatusDto.of(device, isOnline(device, now)))
                .toList();

        List<DeviceCommand> recentCommands =
                deviceCommandRepository.findTop15ByDeletedFalseOrderByRequestedAtDesc();

        return AdminDto.DashboardDto.builder()
                .userCount(userRepository.countByDeletedFalse())
                .growingPlantCount(userPlantRepository.countByStatusInAndDeletedFalse(
                        List.of(UserPlantStatus.GROWING, UserPlantStatus.HARVESTABLE)))
                .harvestedPlantCount(userPlantRepository.countByStatusInAndDeletedFalse(
                        List.of(UserPlantStatus.HARVESTED)))
                .onlineDeviceCount(devices.stream().filter(AdminDto.DeviceStatusDto::isOnline).count())
                .deviceCount(devices.size())
                .failedCommandCount24h(deviceCommandRepository.countByCommandStatusAndRequestedAtAfterAndDeletedFalse(
                        CommandStatus.FAILED, now.minusHours(24)))
                .devices(devices)
                .recentCommands(recentCommands.stream()
                        .limit(RECENT_COMMAND_COUNT)
                        .map(AdminDto.CommandRowDto::from)
                        .toList())
                .build();
    }

    private boolean isOnline(IotDevice device, LocalDateTime now) {
        return Boolean.TRUE.equals(device.getActive())
                && device.getLastConnectedAt() != null
                && device.getLastConnectedAt().isAfter(now.minusMinutes(DEVICE_OFFLINE_MINUTES));
    }
}

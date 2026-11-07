package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.PumpChannelRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

// 재배기(재배 공간) 담당 식물 교체 — 재배기 1대 = 식물 1개 운영 기준
//
// 앱에서 식물을 수확하고 새 씨앗을 심으면, 실제 재배기의 ESP32 토양 센서·펌프 채널·사진은
// 새 식물을 따라가야 한다. 장치 키나 Pi 설정 파일을 다시 만들지 않고 서버 연결만 옮긴다.
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class GrowerAssignmentService {

    private final GrowSpacePlantRepository growSpacePlantRepository;
    private final IotDeviceRepository iotDeviceRepository;
    private final PumpChannelRepository pumpChannelRepository;
    private final AutomationSettingRepository automationSettingRepository;

    // 새 식물을 심었을 때 — 이 사용자의 재배기에 수확이 끝난 식물만 연결돼 있으면 새 식물로 넘긴다.
    // 성장 중인 식물이 연결된 재배기는 건드리지 않는다.
    public Optional<GrowSpace> transferHarvestedGrowerToNewPlant(User user, UserPlant newPlant) {
        if (growSpacePlantRepository.existsByUserPlantAndDeletedFalse(newPlant)) {
            return Optional.empty();
        }

        for (GrowSpacePlant connection :
                growSpacePlantRepository.findAllByUserPlant_UserAndActiveTrueAndDeletedFalse(user)) {
            GrowSpace growSpace = connection.getGrowSpace();

            if (!Boolean.TRUE.equals(growSpace.getActive()) || growSpace.isDeleted()) {
                continue;
            }

            List<GrowSpacePlant> plantsInSpace =
                    growSpacePlantRepository.findAllByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace);

            boolean onlyHarvestedPlants = plantsInSpace.stream()
                    .allMatch(gsp -> gsp.getUserPlant().getStatus() == UserPlantStatus.HARVESTED);

            if (plantsInSpace.size() == 1 && onlyHarvestedPlants) {
                moveGrowSpaceToPlant(growSpace, newPlant);
                log.info("[GROWER] 수확 후 새 식물로 재배기 이전 (growSpaceId={}, newUserPlantId={})",
                        growSpace.getId(), newPlant.getId());
                return Optional.of(growSpace);
            }
        }

        return Optional.empty();
    }

    // 재배 공간의 담당 식물을 newPlant로 교체 — 기존 연결 해제, ESP32·펌프 채널 이전, 자동화 설정 승계
    public GrowSpacePlant moveGrowSpaceToPlant(GrowSpace growSpace, UserPlant newPlant) {
        if (newPlant.getStatus() == UserPlantStatus.HARVESTED) {
            throw new IllegalStateException("수확이 끝난 식물에는 재배기를 연결할 수 없습니다.");
        }

        Optional<GrowSpacePlant> existingOfNewPlant =
                growSpacePlantRepository.findByUserPlantAndActiveTrueAndDeletedFalse(newPlant);

        if (existingOfNewPlant.isPresent()) {
            if (existingOfNewPlant.get().getGrowSpace().getId().equals(growSpace.getId())) {
                return existingOfNewPlant.get();
            }

            throw new IllegalStateException("이 식물은 이미 다른 재배 공간에 연결되어 있습니다.");
        }

        List<GrowSpacePlant> currentPlants =
                growSpacePlantRepository.findAllByGrowSpaceAndActiveTrueAndDeletedFalse(growSpace);

        if (currentPlants.size() > 1) {
            throw new IllegalStateException("식물이 여러 개 연결된 재배 공간은 자동으로 교체할 수 없습니다.");
        }

        UserPlant previousPlant = currentPlants.isEmpty() ? null : currentPlants.get(0).getUserPlant();

        currentPlants.forEach(GrowSpacePlant::disconnect);
        // 연결 해제(soft delete)를 먼저 반영해야 새 연결의 unique 검사와 순서가 섞이지 않는다.
        growSpacePlantRepository.flush();

        GrowSpacePlant newConnection = growSpacePlantRepository.save(
                GrowSpacePlant.connect(growSpace, newPlant)
        );

        for (IotDevice esp : iotDeviceRepository.findAllByGrowSpaceAndDeviceTypeAndDeletedFalse(
                growSpace,
                DeviceType.ESP32
        )) {
            esp.reassignUserPlant(newPlant);
        }

        List<PumpChannel> pumpChannels = pumpChannelRepository.findAllByGrowSpaceAndDeletedFalse(growSpace);

        if (pumpChannels.size() > 1) {
            throw new IllegalStateException("펌프 채널이 여러 개인 재배 공간은 자동으로 교체할 수 없습니다.");
        }

        if (!pumpChannels.isEmpty() && !pumpChannelRepository.existsByUserPlantAndDeletedFalse(newPlant)) {
            pumpChannels.get(0).reassignUserPlant(newPlant);
        }

        inheritAutomationSetting(previousPlant, newPlant);

        return newConnection;
    }

    // 이전 식물의 자동화 설정을 새 식물에 복사 — 새 식물에 설정이 없을 때만
    private void inheritAutomationSetting(UserPlant previousPlant, UserPlant newPlant) {
        if (previousPlant == null) {
            return;
        }

        if (automationSettingRepository.existsByUserPlantAndDeletedFalse(newPlant)) {
            return;
        }

        automationSettingRepository.findByUserPlantAndDeletedFalse(previousPlant)
                .ifPresent(previous -> automationSettingRepository.save(
                        AutomationSetting.copyOf(previous, newPlant.getUser(), newPlant)
                ));
    }
}

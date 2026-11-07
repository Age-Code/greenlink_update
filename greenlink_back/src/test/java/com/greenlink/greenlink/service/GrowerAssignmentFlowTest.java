package com.greenlink.greenlink.service;

import com.greenlink.greenlink.config.DefaultDataInitializer;
import com.greenlink.greenlink.domain.automation.AutomationSetting;
import com.greenlink.greenlink.domain.iot.GrowSpace;
import com.greenlink.greenlink.domain.iot.GrowSpacePlant;
import com.greenlink.greenlink.domain.iot.IotDevice;
import com.greenlink.greenlink.domain.iot.PumpChannel;
import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.dto.UserPlantDto;
import com.greenlink.greenlink.repository.AutomationSettingRepository;
import com.greenlink.greenlink.repository.GrowSpacePlantRepository;
import com.greenlink.greenlink.repository.GrowSpaceRepository;
import com.greenlink.greenlink.repository.IotDeviceRepository;
import com.greenlink.greenlink.repository.ItemRepository;
import com.greenlink.greenlink.repository.PumpChannelRepository;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;

// 재배기 1대 = 식물 1개: 수확 후 새 씨앗을 심으면 ESP 센서·펌프·자동화 설정이 새 식물을 따라가는지
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GrowerAssignmentFlowTest {

    @Autowired
    private AuthService authService;
    @Autowired
    private UserPlantService userPlantService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private ItemRepository itemRepository;
    @Autowired
    private UserItemRepository userItemRepository;
    @Autowired
    private UserPlantRepository userPlantRepository;
    @Autowired
    private GrowSpaceRepository growSpaceRepository;
    @Autowired
    private GrowSpacePlantRepository growSpacePlantRepository;
    @Autowired
    private IotDeviceRepository iotDeviceRepository;
    @Autowired
    private PumpChannelRepository pumpChannelRepository;
    @Autowired
    private AutomationSettingRepository automationSettingRepository;
    @Autowired
    private EntityManager entityManager;

    @Test
    void newSeedAfterHarvestTakesOverTheGrower() {
        authService.signup(new AuthDto.SignupReqDto("grower@example.com", "password", "grower"));
        User user = userRepository.findByEmailAndDeletedFalse("grower@example.com").orElseThrow();
        Item seed = itemRepository.findByNameAndDeletedFalse(DefaultDataInitializer.DEFAULT_SEED_NAME).orElseThrow();

        // 1) 첫 식물 심기 + 재배기 구성
        UserPlant first = plant(user, "첫째");

        GrowSpace growSpace = growSpaceRepository.save(GrowSpace.create("grower-flow", null));
        growSpacePlantRepository.save(GrowSpacePlant.connect(growSpace, first));
        IotDevice pi = iotDeviceRepository.save(IotDevice.createRaspberryPi(growSpace, "flow-pi", "flow-pi-key"));
        IotDevice esp = iotDeviceRepository.save(IotDevice.createEsp32(growSpace, first, "flow-esp", "flow-esp-key"));
        PumpChannel pump = pumpChannelRepository.save(PumpChannel.create(growSpace, first, pi, "pump-1", 22, 1));

        AutomationSetting setting = AutomationSetting.createDefault(user, first);
        setting.updateSetting(true, true, 40.0, null, null, null, null, null, null, null, null, null);
        automationSettingRepository.save(setting);

        // 2) 첫 식물 수확 완료
        ReflectionTestUtils.setField(first, "status", UserPlantStatus.HARVESTED);
        entityManager.flush();

        // 3) 새 씨앗 심기
        userItemRepository.save(UserItem.createOwned(user, seed));
        UserPlant second = plant(user, "둘째");
        entityManager.flush();
        entityManager.clear();

        // 재배기 연결이 새 식물로 옮겨졌다.
        GrowSpacePlant connection = growSpacePlantRepository
                .findByUserPlantAndActiveTrueAndDeletedFalse(userPlantRepository.findById(second.getId()).orElseThrow())
                .orElseThrow();
        assertThat(connection.getGrowSpace().getId()).isEqualTo(growSpace.getId());
        assertThat(growSpacePlantRepository.findAllByGrowSpaceAndActiveTrueAndDeletedFalse(connection.getGrowSpace()))
                .hasSize(1);

        // ESP 토양 센서와 펌프가 새 식물을 담당한다.
        assertThat(iotDeviceRepository.findById(esp.getId()).orElseThrow().getUserPlant().getId())
                .isEqualTo(second.getId());
        assertThat(pumpChannelRepository.findById(pump.getId()).orElseThrow().getUserPlant().getId())
                .isEqualTo(second.getId());

        // 자동화 설정을 이어받는다.
        AutomationSetting inherited = automationSettingRepository
                .findByUserPlantAndDeletedFalse(userPlantRepository.findById(second.getId()).orElseThrow())
                .orElseThrow();
        assertThat(inherited.getAutoWaterEnabled()).isTrue();
        assertThat(inherited.getWaterThresholdPercent()).isEqualTo(40.0);
    }

    @Test
    void growingPlantKeepsTheGrowerWhenAnotherSeedIsPlanted() {
        authService.signup(new AuthDto.SignupReqDto("keeper@example.com", "password", "keeper"));
        User user = userRepository.findByEmailAndDeletedFalse("keeper@example.com").orElseThrow();
        Item seed = itemRepository.findByNameAndDeletedFalse(DefaultDataInitializer.DEFAULT_SEED_NAME).orElseThrow();

        UserPlant growing = plant(user, "자라는중");
        GrowSpace growSpace = growSpaceRepository.save(GrowSpace.create("grower-keep", null));
        growSpacePlantRepository.save(GrowSpacePlant.connect(growSpace, growing));

        userItemRepository.save(UserItem.createOwned(user, seed));
        UserPlant another = plant(user, "새싹");
        entityManager.flush();

        assertThat(growSpacePlantRepository.findByUserPlantAndActiveTrueAndDeletedFalse(growing)).isPresent();
        assertThat(growSpacePlantRepository.findByUserPlantAndActiveTrueAndDeletedFalse(another)).isEmpty();
    }

    private UserPlant plant(User user, String nickname) {
        UserItem ownedSeed = userItemRepository.findAllByUserAndDeletedFalse(user).stream()
                .filter(UserItem::isOwned)
                .filter(item -> item.getItem().getName().equals(DefaultDataInitializer.DEFAULT_SEED_NAME))
                .findFirst()
                .orElseThrow();

        UserPlantDto.CreateResDto created = userPlantService.createUserPlant(
                user.getId(),
                new UserPlantDto.CreateReqDto(ownedSeed.getId(), nickname)
        );

        return userPlantRepository.findById(created.getUserPlantId()).orElseThrow();
    }
}

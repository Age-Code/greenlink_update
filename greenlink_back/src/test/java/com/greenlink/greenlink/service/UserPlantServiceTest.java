package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.UserPlantDto;
import com.greenlink.greenlink.repository.UserItemRepository;
import com.greenlink.greenlink.repository.UserPlantRepository;
import com.greenlink.greenlink.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class UserPlantServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserItemRepository userItemRepository;
    @Mock
    private UserPlantRepository userPlantRepository;
    @Mock
    private QuestProgressService questProgressService;

    @InjectMocks
    private UserPlantService userPlantService;

    @Test
    void getUserPlantsFiltersAfterRefreshingHarvestableStatus() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, 0);
        UserPlant matureGrowingPlant = UserPlant.create(user, plant, "바질이");

        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(userPlantRepository.findAllByUserAndDeletedFalse(user))
                .willReturn(List.of(matureGrowingPlant));

        List<UserPlantDto.ListResDto> result =
                userPlantService.getUserPlants(1L, UserPlantStatus.HARVESTABLE);

        assertThat(result)
                .singleElement()
                .extracting(UserPlantDto.ListResDto::getStatus)
                .isEqualTo(UserPlantStatus.HARVESTABLE.name());
        verify(userPlantRepository).findAllByUserAndDeletedFalse(user);
    }
}

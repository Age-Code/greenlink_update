package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class HomeDtoTest {

    @Test
    void homePlantContainsBothUserPlantIdAndPlantId() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, 30);
        ReflectionTestUtils.setField(plant, "id", 31L);
        UserPlant userPlant = UserPlant.create(user, plant, "내 바질");
        ReflectionTestUtils.setField(userPlant, "id", 41L);

        HomeDto.UserPlantDto dto = HomeDto.UserPlantDto.from(userPlant, LocalDate.now());

        assertThat(dto.getUserPlantId()).isEqualTo(41L);
        assertThat(dto.getPlantId()).isEqualTo(31L);
    }
}

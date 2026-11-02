package com.greenlink.greenlink.domain.plant;

import com.greenlink.greenlink.domain.user.User;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UserPlantNutrientTest {

    @Test
    void nutrientShortensRemainingGrowthByOneDay() {
        UserPlant userPlant = userPlantWithGrowthDays(30);
        LocalDate today = LocalDate.now();

        long before = userPlant.getRemainingDays(today);
        userPlant.applyNutrient(today);

        assertThat(userPlant.getRemainingDays(today)).isEqualTo(before - 1);
        assertThat(userPlant.getGrowthBoostDays()).isEqualTo(1);
    }

    @Test
    void lastNutrientMakesPlantHarvestable() {
        UserPlant userPlant = userPlantWithGrowthDays(1);

        userPlant.applyNutrient(LocalDate.now());

        assertThat(userPlant.getStatus()).isEqualTo(UserPlantStatus.HARVESTABLE);
    }

    @Test
    void nutrientIsRejectedOnceNoLongerGrowing() {
        UserPlant userPlant = userPlantWithGrowthDays(0);

        assertThatThrownBy(() -> userPlant.applyNutrient(LocalDate.now()))
                .isInstanceOf(IllegalStateException.class);
    }

    private UserPlant userPlantWithGrowthDays(int growthDays) {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Plant plant = Plant.create("바질", "HERB", null, null, growthDays);
        return UserPlant.create(user, plant, "바질이");
    }
}

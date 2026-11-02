package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.ai.AiPlantImage;
import com.greenlink.greenlink.domain.iot.PlantImage;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// AiPlantImageRepository — JPA 데이터 접근
public interface AiPlantImageRepository extends JpaRepository<AiPlantImage, Long> {

    // find Top By Plant Image And Deleted False Order By Id Desc 조회 — JPA query method
    Optional<AiPlantImage> findTopByPlantImageAndDeletedFalseOrderByIdDesc(
            PlantImage plantImage
    );

    // find Top By User Plant And Deleted False Order By Id Desc 조회 — JPA query method
    Optional<AiPlantImage> findTopByUserPlantAndDeletedFalseOrderByIdDesc(
            UserPlant userPlant
    );
}

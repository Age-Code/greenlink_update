package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.automation.AutomationModel;
import com.greenlink.greenlink.domain.automation.AutomationModelStatus;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// AutomationModelRepository — JPA 데이터 접근
public interface AutomationModelRepository extends JpaRepository<AutomationModel, Long> {

    // 특정 식물의 최신 학습 모델 조회 — 자동화 판단 시 가장 최근에 학습된 모델을 사용하기 위해 필요하다.
    Optional<AutomationModel> findTopByUserPlantAndDeletedFalseOrderByLastTrainedAtDesc(
            UserPlant userPlant
    );

    // 특정 식물의 사용 가능한 최신 학습 모델 조회 — modelStatus = READY 인 모델만 조회한다.
    Optional<AutomationModel> findTopByUserPlantAndModelStatusAndDeletedFalseOrderByLastTrainedAtDesc(
            UserPlant userPlant,
            AutomationModelStatus modelStatus
    );

    // 특정 식물의 학습 이력 조회
    List<AutomationModel> findByUserPlantAndDeletedFalseOrderByLastTrainedAtDesc(
            UserPlant userPlant
    );
}
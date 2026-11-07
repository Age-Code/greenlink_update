package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.automation.AutomationLog;
import com.greenlink.greenlink.domain.automation.AutomationType;
import com.greenlink.greenlink.domain.iot.DeviceCommand;
import com.greenlink.greenlink.domain.plant.UserPlant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

// AutomationLogRepository — JPA 데이터 접근
public interface AutomationLogRepository extends JpaRepository<AutomationLog, Long> {

    // 자동화가 만든 명령인지 — 자동 급수는 사용자 퀘스트(물 주기) 진행에 넣지 않는다.
    boolean existsByCommandAndDeletedFalse(DeviceCommand command);

    // 같은 SKIP 사유 연속 저장 방지용 — 식물·유형별 마지막 로그
    Optional<AutomationLog> findTopByUserPlantAndAutomationTypeAndDeletedFalseOrderByIdDesc(
            UserPlant userPlant,
            AutomationType automationType
    );

    // 특정 식물의 자동화 로그 최신순 조회
    List<AutomationLog> findByUserPlantAndDeletedFalseOrderByCreatedAtDesc(
            UserPlant userPlant
    );

    // 특정 식물의 자동화 로그 중 최근 N개 조회용 — Service에서 Pageable로 처리해도 되지만,
    List<AutomationLog> findTop30ByUserPlantAndDeletedFalseOrderByCreatedAtDesc(
            UserPlant userPlant
    );

    // 특정 식물의 자동화 로그 중 최근 5개 조회
    List<AutomationLog> findTop5ByUserPlantAndDeletedFalseOrderByCreatedAtDesc(
            UserPlant userPlant
    );

    // 특정 식물의 특정 자동화 타입 로그 조회
    List<AutomationLog> findByUserPlantAndAutomationTypeAndDeletedFalseOrderByCreatedAtDesc(
            UserPlant userPlant,
            AutomationType automationType
    );

    // 특정 시간 이후의 자동화 로그 조회 — 학습/분석에서 최근 7일, 최근 24시간 로그를 조회할 때 사용한다.
    List<AutomationLog> findByUserPlantAndCreatedAtAfterAndDeletedFalseOrderByCreatedAtDesc(
            UserPlant userPlant,
            LocalDateTime createdAt
    );
}

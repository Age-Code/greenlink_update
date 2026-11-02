package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.iot.GrowSpace;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// GrowSpaceRepository — JPA 데이터 접근
public interface GrowSpaceRepository extends JpaRepository<GrowSpace, Long> {

    // find All By Deleted False 조회 — JPA query method
    List<GrowSpace> findAllByDeletedFalse();

    // find All By Active True And Deleted False 조회 — JPA query method
    List<GrowSpace> findAllByActiveTrueAndDeletedFalse();

    // find By Id And Deleted False 조회 — JPA query method
    Optional<GrowSpace> findByIdAndDeletedFalse(Long id);

    // find By Id And Active True And Deleted False 조회 — JPA query method
    Optional<GrowSpace> findByIdAndActiveTrueAndDeletedFalse(Long id);

    // exists By Name And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByNameAndDeletedFalse(String name);
}

package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.plant.Plant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// PlantRepository — JPA 데이터 접근
public interface PlantRepository extends JpaRepository<Plant, Long> {

    // find All By Deleted False 조회 — JPA query method
    List<Plant> findAllByDeletedFalse();

    // find By Id And Deleted False 조회 — JPA query method
    Optional<Plant> findByIdAndDeletedFalse(Long id);

    // find By Name And Deleted False 조회 — JPA query method
    Optional<Plant> findByNameAndDeletedFalse(String name);

    // exists By Name And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByNameAndDeletedFalse(String name);
}

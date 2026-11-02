package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.domain.plant.UserPlant;
import com.greenlink.greenlink.domain.plant.UserPlantStatus;
import com.greenlink.greenlink.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

// UserPlantRepository — JPA 데이터 접근
public interface UserPlantRepository extends JpaRepository<UserPlant, Long> {

    // find All By User And Deleted False 조회 — JPA query method
    List<UserPlant> findAllByUserAndDeletedFalse(User user);

    // find By Id And User And Deleted False 조회 — JPA query method
    Optional<UserPlant> findByIdAndUserAndDeletedFalse(Long id, User user);

    // count By User And Plant And Status And Deleted False 개수 조회 — JPA query method
    long countByUserAndPlantAndStatusAndDeletedFalse(
            User user,
            Plant plant,
            UserPlantStatus status
    );

    // exists By User And Plant And Status And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByUserAndPlantAndStatusAndDeletedFalse(
            User user,
            Plant plant,
            UserPlantStatus status
    );

    // find All By User And Plant And Status And Deleted False 조회 — JPA query method
    List<UserPlant> findAllByUserAndPlantAndStatusAndDeletedFalse(
            User user,
            Plant plant,
            UserPlantStatus status
    );

    // find All By User And Plant And Status And Deleted False Order By Harvested At Asc 조회 — JPA query method
    List<UserPlant> findAllByUserAndPlantAndStatusAndDeletedFalseOrderByHarvestedAtAsc(
            User user,
            Plant plant,
            UserPlantStatus status
    );

    // find First By User And Status In And Deleted False Order By Created At Desc 조회 — JPA query method
    Optional<UserPlant> findFirstByUserAndStatusInAndDeletedFalseOrderByCreatedAtDesc(
            User user,
            Collection<UserPlantStatus> statuses
    );

    // find First By User And Deleted False Order By Created At Desc 조회 — JPA query method
    Optional<UserPlant> findFirstByUserAndDeletedFalseOrderByCreatedAtDesc(User user);

    // find By Id And Deleted False 조회 — JPA query method
    Optional<UserPlant> findByIdAndDeletedFalse(Long id);
}

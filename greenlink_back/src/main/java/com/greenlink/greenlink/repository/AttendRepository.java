package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.attend.Attend;
import com.greenlink.greenlink.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

// AttendRepository — JPA 데이터 접근
public interface AttendRepository extends JpaRepository<Attend, Long> {

    // find By User And Attend Date 조회 — JPA query method
    Optional<Attend> findByUserAndAttendDate(User user, LocalDate attendDate);

    // exists By User And Attend Date 존재 여부 조회 — JPA query method
    boolean existsByUserAndAttendDate(User user, LocalDate attendDate);

    // find All By User And Attend Date Between Order By Attend Date Asc 조회 — JPA query method
    List<Attend> findAllByUserAndAttendDateBetweenOrderByAttendDateAsc(
            User user,
            LocalDate startDate,
            LocalDate endDate
    );

    // find Top By User And Attend Date Less Than Equal Order By Attend Date Desc 조회 — JPA query method
    Optional<Attend> findTopByUserAndAttendDateLessThanEqualOrderByAttendDateDesc(
            User user,
            LocalDate attendDate
    );
}

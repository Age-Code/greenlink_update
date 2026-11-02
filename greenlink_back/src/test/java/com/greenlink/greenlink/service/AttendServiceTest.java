package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.attend.Attend;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AttendDto;
import com.greenlink.greenlink.repository.AttendRepository;
import com.greenlink.greenlink.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class AttendServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private AttendRepository attendRepository;
    @Mock
    private QuestProgressService questProgressService;

    @InjectMocks
    private AttendService attendService;

    @Test
    void currentStreakIncludesAttendanceToday() {
        LocalDate today = LocalDate.now();

        AttendDto.AttendMonthResDto result = getMonthlyAttendsWithLatestAttend(today, 5);

        assertThat(result.getCurrentStreakCount()).isEqualTo(5);
    }

    @Test
    void currentStreakIncludesAttendanceYesterday() {
        LocalDate today = LocalDate.now();

        AttendDto.AttendMonthResDto result = getMonthlyAttendsWithLatestAttend(today.minusDays(1), 5);

        assertThat(result.getCurrentStreakCount()).isEqualTo(5);
    }

    @Test
    void currentStreakIsZeroWhenLastAttendanceWasBeforeYesterday() {
        LocalDate today = LocalDate.now();

        AttendDto.AttendMonthResDto result = getMonthlyAttendsWithLatestAttend(today.minusDays(2), 5);

        assertThat(result.getCurrentStreakCount()).isZero();
    }

    private AttendDto.AttendMonthResDto getMonthlyAttendsWithLatestAttend(
            LocalDate latestAttendDate,
            int streakCount
    ) {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        LocalDate today = LocalDate.now();
        Attend latestAttend = Attend.create(user, latestAttendDate, streakCount);

        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(attendRepository.findAllByUserAndAttendDateBetweenOrderByAttendDateAsc(
                user,
                today.withDayOfMonth(1),
                today.withDayOfMonth(today.lengthOfMonth())
        )).willReturn(List.of());
        given(attendRepository.findTopByUserAndAttendDateLessThanEqualOrderByAttendDateDesc(user, today))
                .willReturn(Optional.of(latestAttend));

        return attendService.getMyAttends(1L, today.getYear(), today.getMonthValue());
    }
}

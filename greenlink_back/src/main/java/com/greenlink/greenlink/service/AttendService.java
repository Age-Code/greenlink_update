package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.attend.Attend;
import com.greenlink.greenlink.domain.quest.TargetType;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.AttendDto;
import com.greenlink.greenlink.repository.AttendRepository;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

// AttendService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AttendService {

    private final UserRepository userRepository;
    private final AttendRepository attendRepository;
    private final QuestProgressService questProgressService;

    // 오늘 출석 처리
    @Transactional
    public AttendDto.AttendTodayResDto attendToday(Long userId) {
        User user = findActiveUser(userId);
        LocalDate today = LocalDate.now();

        if (attendRepository.existsByUserAndAttendDate(user, today)) {
            throw new IllegalStateException("오늘은 이미 출석했습니다.");
        }

        LocalDate yesterday = today.minusDays(1);

        int streakCount = attendRepository.findByUserAndAttendDate(user, yesterday)
                .map(previousAttend -> previousAttend.getStreakCount() + 1)
                .orElse(1);

        Attend attend = Attend.create(user, today, streakCount);
        Attend savedAttend = attendRepository.save(attend);

        questProgressService.increaseProgress(user, TargetType.ATTEND, 1);

        return AttendDto.AttendTodayResDto.from(savedAttend);
    }

    public AttendDto.AttendMonthResDto getMyAttends(Long userId, Integer year, Integer month) {
        User user = findActiveUser(userId);

        YearMonth targetMonth = resolveYearMonth(year, month);

        LocalDate startDate = targetMonth.atDay(1);
        LocalDate endDate = targetMonth.atEndOfMonth();

        List<Attend> attends = attendRepository
                .findAllByUserAndAttendDateBetweenOrderByAttendDateAsc(user, startDate, endDate);

        LocalDate today = LocalDate.now();
        Integer currentStreakCount = attendRepository
                .findTopByUserAndAttendDateLessThanEqualOrderByAttendDateDesc(user, today)
                .filter(attend -> !attend.getAttendDate().isBefore(today.minusDays(1)))
                .map(Attend::getStreakCount)
                .orElse(0);

        return AttendDto.AttendMonthResDto.of(
                targetMonth.getYear(),
                targetMonth.getMonthValue(),
                attends,
                currentStreakCount
        );
    }

    // resolve Year Month 처리
    private YearMonth resolveYearMonth(Integer year, Integer month) {
        if (year == null && month == null) {
            return YearMonth.now();
        }

        if (year == null || month == null) {
            throw new IllegalArgumentException("year와 month는 함께 전달해야 합니다.");
        }

        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("month는 1부터 12 사이여야 합니다.");
        }

        return YearMonth.of(year, month);
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findById(userId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

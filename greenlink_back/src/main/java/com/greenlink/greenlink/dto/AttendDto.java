package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.attend.Attend;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

// AttendDto — API 요청/응답 DTO
public class AttendDto {

    // AttendTodayResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttendTodayResDto {
        private Long attendId;
        private LocalDate attendDate;
        private Integer streakCount;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static AttendTodayResDto from(Attend attend) {
            return AttendTodayResDto.builder()
                    .attendId(attend.getId())
                    .attendDate(attend.getAttendDate())
                    .streakCount(attend.getStreakCount())
                    .build();
        }
    }

    // AttendDayResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttendDayResDto {
        private LocalDate attendDate;
        private Integer streakCount;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static AttendDayResDto from(Attend attend) {
            return AttendDayResDto.builder()
                    .attendDate(attend.getAttendDate())
                    .streakCount(attend.getStreakCount())
                    .build();
        }
    }

    // AttendMonthResDto DTO — API 요청/응답 데이터
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttendMonthResDto {
        private Integer year;
        private Integer month;
        private Integer totalAttendCount;
        private Integer currentStreakCount;
        private List<AttendDayResDto> attends;

        // DTO 변환 — Entity 또는 원시 데이터를 응답 모델로 매핑
        public static AttendMonthResDto of(
                Integer year,
                Integer month,
                List<Attend> attends,
                Integer currentStreakCount
        ) {
            return AttendMonthResDto.builder()
                    .year(year)
                    .month(month)
                    .totalAttendCount(attends.size())
                    .currentStreakCount(currentStreakCount)
                    .attends(
                            attends.stream()
                                    .map(AttendDayResDto::from)
                                    .toList()
                    )
                    .build();
        }
    }
}

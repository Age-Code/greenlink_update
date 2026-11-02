// 출석 API 모델

// AttendMonth — 출석 API 모델
class AttendMonth {
  final int year;
  final int month;
  final int totalAttendCount;
  final int currentStreakCount;
  final List<AttendDay> attends;

  AttendMonth({
    required this.year,
    required this.month,
    required this.totalAttendCount,
    required this.currentStreakCount,
    required this.attends,
  });

  // JSON 응답을 모델로 변환
  factory AttendMonth.fromJson(Map<String, dynamic> json) => AttendMonth(
        year: json['year'] ?? 0,
        month: json['month'] ?? 0,
        totalAttendCount: json['totalAttendCount'] ?? 0,
        currentStreakCount: json['currentStreakCount'] ?? 0,
        attends: (json['attends'] as List?)
                ?.map((e) => AttendDay.fromJson(e))
                .toList() ??
            [],
      );
}

// AttendDay — 출석 API 모델
class AttendDay {
  final String attendDate; // "yyyy-MM-dd"
  final int streakCount;

  AttendDay({required this.attendDate, required this.streakCount});

  // JSON 응답을 모델로 변환
  factory AttendDay.fromJson(Map<String, dynamic> json) => AttendDay(
        attendDate: json['attendDate'] ?? '',
        streakCount: json['streakCount'] ?? 0,
      );
}

// AttendTodayResponse — API 응답 모델
class AttendTodayResponse {
  final bool isConsecutive;
  final int streakDays;

  AttendTodayResponse({required this.isConsecutive, required this.streakDays});

  // JSON 응답을 모델로 변환
  factory AttendTodayResponse.fromJson(Map<String, dynamic> json) {
    final int streakCount = json['streakCount'] ?? json['streakDays'] ?? 1;
    return AttendTodayResponse(
      isConsecutive: streakCount > 1,
      streakDays: streakCount,
    );
  }
}

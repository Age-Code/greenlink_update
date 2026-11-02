package com.greenlink.greenlink.domain.attend;

import com.greenlink.greenlink.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Entity
@Table(
        name = "attend",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_attend_user_date",
                        columnNames = {"user_id", "attend_date"}
                )
        }
)
// Attend — 도메인 모델
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Attend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 출석한 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 출석 날짜
    @Column(name = "attend_date", nullable = false)
    private LocalDate attendDate;

    // 출석 시간
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // 연속 출석 일수
    @Column(name = "streak_count", nullable = false)
    private Integer streakCount;

    // Attend 생성
    private Attend(User user, LocalDate attendDate, Integer streakCount) {
        this.user = user;
        this.attendDate = attendDate;
        this.streakCount = streakCount;
    }

    // create 생성
    public static Attend create(User user, LocalDate attendDate, Integer streakCount) {
        return new Attend(user, attendDate, streakCount);
    }

    // 생성 시각 초기화
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
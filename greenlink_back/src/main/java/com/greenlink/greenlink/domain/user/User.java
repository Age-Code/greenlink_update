package com.greenlink.greenlink.domain.user;

import com.greenlink.greenlink.common.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

// User — 도메인 모델
@Getter
@Entity
@Table(name = "users")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 로그인 이메일
    @Column(nullable = false, unique = true, length = 100)
    private String email;

    // 암호화된 비밀번호
    @Column(nullable = false)
    private String password;

    // 닉네임
    @Column(nullable = false, length = 50)
    private String nickname;

    // 사용자 권한
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserRole role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LoginProvider provider;

    @Column
    private String providerId;

    @Column
    private String profileImageUrl;

    // JWT 무효화용 토큰 버전 — 로그아웃/탈퇴/비밀번호 변경 시 증가
    @Column(nullable = false)
    private int tokenVersion = 0;

    // User 생성
    private User(
            String email,
            String password,
            String nickname,
            UserRole role,
            LoginProvider provider,
            String providerId,
            String profileImageUrl) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
        this.role = role;
        this.provider = provider;
        this.providerId = providerId;
        this.profileImageUrl = profileImageUrl;
    }

    // create User 생성
    public static User createUser(String email, String encodedPassword, String nickname) {
        return new User(
                email,
                encodedPassword,
                nickname,
                UserRole.USER,
                LoginProvider.LOCAL,
                null,
                null);
    }

    // create Admin 생성
    public static User createAdmin(String email, String encodedPassword, String nickname) {
        return new User(
                email,
                encodedPassword,
                nickname,
                UserRole.ADMIN,
                LoginProvider.LOCAL,
                null,
                null);
    }

    // create OAuth User 생성
    public static User createOAuthUser(
            String email,
            String encodedPassword,
            String nickname,
            LoginProvider provider,
            String providerId,
            String profileImageUrl) {
        return new User(
                email,
                encodedPassword,
                nickname,
                UserRole.USER,
                provider,
                providerId,
                profileImageUrl);
    }

    // 관리자 권한 토글
    public void toggleRole() {
        this.role = (this.role == UserRole.USER) ? UserRole.ADMIN : UserRole.USER;
    }

    // update Nickname 수정
    public void updateNickname(String nickname) {
        this.nickname = nickname;
    }

    // 토큰 버전 증가 — 기존 발급 JWT 무효화
    public void incrementTokenVersion() {
        this.tokenVersion++;
    }

    // 비밀번호 변경 — 기존 발급 JWT 무효화
    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
        incrementTokenVersion();
    }

    // 회원 탈퇴 — soft delete 후 기존 발급 JWT 무효화
    // email은 DB unique이므로 탈퇴 계정의 email·providerId를 비워 같은 이메일로 재가입/재로그인할 수 있게 한다.
    public void withdraw() {
        delete();
        this.email = "withdrawn-" + this.id + "-" + java.util.UUID.randomUUID().toString().substring(0, 8)
                + "@withdrawn.invalid";
        this.providerId = null;
        incrementTokenVersion();
    }

    // 로그아웃 — 기존 발급 JWT 무효화
    public void logout() {
        incrementTokenVersion();
    }
}

package com.greenlink.greenlink.repository;

import com.greenlink.greenlink.domain.user.LoginProvider;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.domain.user.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// UserRepository — JPA 데이터 접근
public interface UserRepository extends JpaRepository<User, Long> {

    // find By Email And Deleted False 조회 — JPA query method
    Optional<User> findByEmailAndDeletedFalse(String email);

    // find By Id And Deleted False 조회 — JPA query method
    Optional<User> findByIdAndDeletedFalse(Long id);

    // exists By Email And Deleted False 존재 여부 조회 — JPA query method
    boolean existsByEmailAndDeletedFalse(String email);

    // email unique 제약은 탈퇴 계정에도 걸리므로 가입 전 중복 검사는 삭제 여부와 무관하게 한다.
    boolean existsByEmail(String email);

    // 최초 관리자 부트스트랩 판단용
    boolean existsByRoleAndDeletedFalse(UserRole role);

    // find By Provider And Provider Id And Deleted False 조회 — JPA query method
    Optional<User> findByProviderAndProviderIdAndDeletedFalse(
            LoginProvider provider,
            String providerId);

    // find All By Deleted False 조회 — JPA query method
    java.util.List<User> findAllByDeletedFalse();
}

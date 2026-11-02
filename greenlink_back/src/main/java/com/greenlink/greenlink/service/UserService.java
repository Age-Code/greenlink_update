package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.user.LoginProvider;
import com.greenlink.greenlink.domain.user.User;
import com.greenlink.greenlink.dto.UserDto;
import com.greenlink.greenlink.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// UserService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserDto.MeResDto getMe(Long userId) {
        User user = findActiveUser(userId);

        return UserDto.MeResDto.from(user);
    }

    // update Nickname 수정
    @Transactional
    public UserDto.UpdateNicknameResDto updateNickname(
            Long userId,
            UserDto.UpdateNicknameReqDto request
    ) {
        User user = findActiveUser(userId);

        user.updateNickname(request.getNickname());

        return UserDto.UpdateNicknameResDto.from(user);
    }

    // 비밀번호 변경 — LOCAL 유저만, 현재 비밀번호 검증 후 기존 JWT 무효화
    @Transactional
    public void changePassword(Long userId, UserDto.ChangePasswordReqDto request) {
        User user = findActiveUser(userId);

        if (user.getProvider() != LoginProvider.LOCAL) {
            throw new IllegalArgumentException("소셜 로그인 계정은 비밀번호를 변경할 수 없습니다.");
        }

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        user.changePassword(passwordEncoder.encode(request.getNewPassword()));
    }

    // 회원 탈퇴 — soft delete 후 기존 JWT 무효화
    @Transactional
    public void withdraw(Long userId) {
        User user = findActiveUser(userId);
        user.withdraw();
    }

    // 로그아웃 — tokenVersion 증가로 기존 JWT 무효화
    @Transactional
    public void logout(Long userId) {
        User user = findActiveUser(userId);
        user.logout();
    }

    // find Active User 조회 — 없으면 예외 또는 Optional 반환
    private User findActiveUser(Long userId) {
        return userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}

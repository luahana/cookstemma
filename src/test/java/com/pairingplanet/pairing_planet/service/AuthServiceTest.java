package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.Auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.Auth.TokenReissueRequestDto;
import com.pairingplanet.pairing_planet.repository.user.SocialAccountRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.JwtTokenProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @InjectMocks AuthService authService;
    @Mock
    UserRepository userRepository;
    @Mock
    SocialAccountRepository socialAccountRepository;
    @Mock
    JwtTokenProvider jwtTokenProvider;

    @Test
    @DisplayName("토큰 재발급 성공: Refresh Token이 교체되어야 한다 (Sliding Expiration & RTR)")
    void reissue_Success() {
        // given
        String oldRefreshToken = "old-refresh-token";
        String newAccessToken = "new-access-token";
        String newRefreshToken = "new-refresh-token";
        UUID publicId = UUID.randomUUID();
        String role = "USER";

        // 유저 세팅: DB에 저장된 토큰이 요청 온 토큰과 일치하는 상태
        User user = User.builder()
                .role(role)
                .username("test")
                .appRefreshToken(oldRefreshToken)
                .build();

        // Mocks
        given(jwtTokenProvider.validateToken(oldRefreshToken)).willReturn(true);
        given(jwtTokenProvider.getSubject(oldRefreshToken)).willReturn(publicId.toString());
        given(userRepository.findByPublicId(publicId)).willReturn(Optional.of(user));

        // 새 토큰 생성 Mock
        given(jwtTokenProvider.createAccessToken(any(), eq("USER"))).willReturn(newAccessToken);
        given(jwtTokenProvider.createRefreshToken(any())).willReturn(newRefreshToken);

        // when
        AuthResponseDto response = authService.reissue(new TokenReissueRequestDto(oldRefreshToken));

        // then
        assertThat(response.accessToken()).isEqualTo(newAccessToken);
        assertThat(response.refreshToken()).isEqualTo(newRefreshToken);

        // 핵심 검증: User 객체의 Refresh Token이 새것으로 바뀌었는지 확인 (RTR)
        assertThat(user.getAppRefreshToken()).isEqualTo(newRefreshToken);
    }

    @Test
    @DisplayName("토큰 재발급 실패: DB의 토큰과 불일치하면(탈취 의심) 토큰을 파기하고 예외 발생")
    void reissue_Fail_TokenMismatch() {
        // given
        String requestRefreshToken = "stolen-refresh-token";
        String dbRefreshToken = "original-refresh-token";
        UUID publicId = UUID.randomUUID();

        // 유저 세팅: DB에는 다른 토큰이 저장되어 있음
        User user = User.builder()
                .appRefreshToken(dbRefreshToken)
                .build();

        given(jwtTokenProvider.validateToken(requestRefreshToken)).willReturn(true);
        given(jwtTokenProvider.getSubject(requestRefreshToken)).willReturn(publicId.toString());
        given(userRepository.findByPublicId(publicId)).willReturn(Optional.of(user));

        // when & then
        assertThatThrownBy(() -> authService.reissue(new TokenReissueRequestDto(requestRefreshToken)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Security Alert");

        // 핵심 검증: 보안을 위해 DB에 저장된 토큰마저 null로 밀어버려야 함 (강제 로그아웃)
        assertThat(user.getAppRefreshToken()).isNull();
    }
}
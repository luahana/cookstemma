package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.user.SocialAccount;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.Auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.Auth.SocialLoginRequestDto;
import com.pairingplanet.pairing_planet.dto.Auth.TokenReissueRequestDto;
import com.pairingplanet.pairing_planet.repository.user.SocialAccountRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final SocialAccountRepository socialAccountRepository;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public AuthResponseDto socialLogin(SocialLoginRequestDto req) {
        // 1. 소셜 계정 조회 혹은 신규 생성
        SocialAccount socialAccount = socialAccountRepository
                .findByProviderAndProviderUserId(req.provider(), req.providerUserId())
                .orElseGet(() -> registerNewUser(req));

        User user = socialAccount.getUser();

        // 2. 소셜 토큰 업데이트 (암호화 Converter 자동 동작)
        socialAccount.setAccessToken(req.socialAccessToken());
        if (req.socialRefreshToken() != null) {
            socialAccount.setRefreshToken(req.socialRefreshToken());
        }

        // 3. 앱 로그인 처리 (토큰 발급 + RTR 저장)
        return performLogin(user);
    }

    @Transactional
    public AuthResponseDto reissue(TokenReissueRequestDto req) {
        // 1. Refresh Token 검증
        if (!jwtTokenProvider.validateToken(req.refreshToken())) {
            throw new IllegalArgumentException("Invalid Refresh Token");
        }

        UUID publicId = UUID.fromString(jwtTokenProvider.getSubject(req.refreshToken()));

        // 2. DB 저장된 토큰과 비교 (RTR: 이미 사용된 토큰인지, 탈취된 토큰인지 확인)
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getAppRefreshToken() == null || !user.getAppRefreshToken().equals(req.refreshToken())) {
            // 토큰 불일치: 탈취 가능성 높음 -> 강제 로그아웃 (토큰 파기)
            user.setAppRefreshToken(null);
            throw new IllegalArgumentException("Security Alert: Invalid Token detected. Please login again.");
        }

        // 3. 토큰 회전 (Rotation) 및 재발급
        return performLogin(user);
    }

    // 공통 로그인 처리 (토큰 생성 + DB 저장)
    private AuthResponseDto performLogin(User user) {
        String accessToken = jwtTokenProvider.createAccessToken(user.getPublicId(), user.getRole());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getPublicId());

        // Sliding Expiration: 새 Refresh Token을 DB에 저장 (기존 것 덮어쓰기)
        user.setAppRefreshToken(refreshToken);
        user.setLastLoginAt(Instant.now());

        return new AuthResponseDto(accessToken, refreshToken, user.getPublicId(), user.getUsername());
    }

    private SocialAccount registerNewUser(SocialLoginRequestDto req) {
        String username = req.username();
        if (username == null || userRepository.existsByUsername(username)) {
            username = "user_" + UUID.randomUUID().toString().substring(0, 8);
        }

        User user = User.builder()
                .username(username)
                .email(req.email())
                .profileImageUrl(req.profileImageUrl())
                .role("USER")
                .status("ACTIVE")
                .locale("ko")
                .build();
        userRepository.save(user);

        SocialAccount account = SocialAccount.builder()
                .user(user)
                .provider(req.provider())
                .providerUserId(req.providerUserId())
                // 토큰은 나중에 setAccessToken으로 들어갈 때 암호화됨, 초기 빌더에선 null이어도 무방하나 여기선 생략
                .build();
        return socialAccountRepository.save(account);
    }
}
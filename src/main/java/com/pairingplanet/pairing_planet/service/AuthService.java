package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.user.SocialAccount;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.Provider;
import com.pairingplanet.pairing_planet.domain.enums.Role;
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
        // DTO에서 넘어온 String을 Enum으로 변환
        Provider provider = req.provider();

        // Repository 메서드 인자 타입에 맞춰 provider 전달
        SocialAccount socialAccount = socialAccountRepository
                .findByProviderAndProviderUserId(provider.name(), req.providerUserId())
                .orElseGet(() -> registerNewUser(req));

        User user = socialAccount.getUser();

        // 2. 소셜 토큰 업데이트
        socialAccount.setAccessToken(req.socialAccessToken());
        if (req.socialRefreshToken() != null) {
            socialAccount.setRefreshToken(req.socialRefreshToken());
        }

        // 3. 앱 로그인 처리
        return performLogin(user);
    }

    @Transactional
    public AuthResponseDto reissue(TokenReissueRequestDto req) {
        if (!jwtTokenProvider.validateToken(req.refreshToken())) {
            throw new IllegalArgumentException("Invalid Refresh Token");
        }

        UUID publicId = UUID.fromString(jwtTokenProvider.getSubject(req.refreshToken()));

        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getAppRefreshToken() == null || !user.getAppRefreshToken().equals(req.refreshToken())) {
            user.setAppRefreshToken(null);
            throw new IllegalArgumentException("Security Alert: Invalid Token detected. Please login again.");
        }

        return performLogin(user);
    }

    private AuthResponseDto performLogin(User user) {
        // [수정] user.getRole() (Enum) -> .name() (String) 으로 변환하여 전달
        String accessToken = jwtTokenProvider.createAccessToken(user.getPublicId(), user.getRole().name());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getPublicId());

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
                .role(Role.USER)
                .status(AccountStatus.ACTIVE)
                .locale("ko")
                .build();
        userRepository.save(user);


        SocialAccount account = SocialAccount.builder()
                .user(user)
                .provider(req.provider()) // 엔티티 필드가 String인 경우 .name(), Enum인 경우 객체 전달
                .providerUserId(req.providerUserId())
                .build();
        return socialAccountRepository.save(account);
    }
}
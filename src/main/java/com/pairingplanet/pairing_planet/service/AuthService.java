package com.pairingplanet.pairing_planet.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.pairingplanet.pairing_planet.domain.entity.user.SocialAccount;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.Provider;
import com.pairingplanet.pairing_planet.domain.enums.Role;
import com.pairingplanet.pairing_planet.dto.auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.auth.SocialLoginRequestDto;
import com.pairingplanet.pairing_planet.dto.auth.TokenReissueRequestDto;
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
        try {
            // 1. Firebase ID Token 검증 및 정보 추출
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(req.idToken());
            String uid = decodedToken.getUid();
            String email = decodedToken.getEmail();
            String name = (String) decodedToken.getClaims().get("name");
            String picture = (String) decodedToken.getClaims().get("picture");

            // [보완] Firebase 내부에서 어떤 Provider(Google/Apple)로 로그인했는지 정확히 추출
            java.util.Map<String, Object> firebaseClaim = (java.util.Map<String, Object>) decodedToken.getClaims().get("firebase");
            String signInProvider = (String) firebaseClaim.get("sign_in_provider");
            Provider provider = convertProvider(signInProvider);

            // 2. 소셜 계정 조회 혹은 신규 생성
            SocialAccount socialAccount = socialAccountRepository
                    .findByProviderAndProviderUserId(provider, uid)
                    .orElseGet(() -> registerNewFirebaseUser(uid, email, name, picture, provider, req.locale()));

            User user = socialAccount.getUser();

            // 3. 로케일 업데이트 (사용자 언어 설정 반영)
            if (req.locale() != null && !req.locale().isBlank()) {
                user.setLocale(req.locale());
            }

            return performLogin(user);

        } catch (FirebaseAuthException e) {
            // [보완] 토큰 만료나 위변조 시 명확한 예외 메시지 전달
            throw new IllegalArgumentException("Firebase 인증 실패: " + e.getAuthErrorCode());
        }
    }

    private Provider convertProvider(String signInProvider) {
        if (signInProvider.contains("google")) return Provider.GOOGLE;
        if (signInProvider.contains("apple")) return Provider.APPLE;
        throw new IllegalArgumentException("지원하지 않는 로그인 수단입니다: " + signInProvider);
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

    private SocialAccount registerNewFirebaseUser(String uid, String email, String name, String picture, Provider provider, String locale) {
        // 기존 registerNewUser 로직을 Firebase 데이터에 맞게 통합
        String username = name;
        if (username == null || userRepository.existsByUsername(username)) {
            username = "user_" + UUID.randomUUID().toString().substring(0, 8);
        }

        User user = User.builder()
                .username(username)
                .email(email)
                .profileImageUrl(picture)
                .role(Role.USER)
                .status(AccountStatus.ACTIVE)
                .locale(locale != null ? locale : "ko-KR")
                .build();
        userRepository.save(user);

        SocialAccount account = SocialAccount.builder()
                .user(user)
                .provider(provider)
                .providerUserId(uid)
                .build();
        return socialAccountRepository.save(account);
    }
}
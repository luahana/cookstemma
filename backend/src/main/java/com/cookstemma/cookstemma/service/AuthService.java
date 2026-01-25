package com.cookstemma.cookstemma.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.cookstemma.cookstemma.domain.entity.user.SocialAccount;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.Provider;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.dto.auth.AuthResponseDto;
import com.cookstemma.cookstemma.dto.auth.SocialLoginRequestDto;
import com.cookstemma.cookstemma.dto.auth.TokenReissueRequestDto;
import com.cookstemma.cookstemma.repository.user.SocialAccountRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.JwtTokenProvider;
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
    private final UserService userService;

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
            throw new IllegalArgumentException("Firebase authentication failed: " + e.getAuthErrorCode());
        }
    }

    private Provider convertProvider(String signInProvider) {
        if (signInProvider.contains("google")) return Provider.GOOGLE;
        if (signInProvider.contains("apple")) return Provider.APPLE;
        throw new IllegalArgumentException("Unsupported login provider: " + signInProvider);
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
        // 소프트 삭제된 계정이면 복구 (30일 유예 기간 내 재로그인)
        userService.restoreDeletedAccount(user);

        // [수정] user.getRole() (Enum) -> .name() (String) 으로 변환하여 전달
        String accessToken = jwtTokenProvider.createAccessToken(user.getPublicId(), user.getRole().name());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getPublicId());

        user.setAppRefreshToken(refreshToken);
        user.setLastLoginAt(Instant.now());

        return new AuthResponseDto(accessToken, refreshToken, user.getPublicId(), user.getUsername(), user.getRole());
    }

    private SocialAccount registerNewFirebaseUser(String uid, String email, String name, String picture, Provider provider, String locale) {
        // Email-based account linking: Check if user with this email already exists
        User user = userRepository.findByEmail(email)
                .orElseGet(() -> createNewUser(email, name, picture, locale));

        // Link new social account to existing/new user
        SocialAccount account = SocialAccount.builder()
                .user(user)
                .provider(provider)
                .providerUserId(uid)
                .build();
        return socialAccountRepository.save(account);
    }

    private User createNewUser(String email, String name, String picture, String locale) {
        String username = name;
        if (username == null || userRepository.existsByUsername(username)) {
            username = "user_" + UUID.randomUUID().toString().substring(0, 8);
        }

        // Auto-admin for specific email
        Role role = "truepark0@gmail.com".equalsIgnoreCase(email) ? Role.ADMIN : Role.USER;

        User user = User.builder()
                .username(username)
                .email(email)
                .profileImageUrl(picture)
                .role(role)
                .status(AccountStatus.ACTIVE)
                .locale(locale != null ? locale : "ko-KR")
                .build();
        return userRepository.save(user);
    }
}
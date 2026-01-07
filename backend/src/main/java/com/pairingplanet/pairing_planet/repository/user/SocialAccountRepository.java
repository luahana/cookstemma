package com.pairingplanet.pairing_planet.repository.user;

import com.pairingplanet.pairing_planet.domain.entity.user.SocialAccount;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.Provider;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;


public interface SocialAccountRepository extends JpaRepository<SocialAccount, Long> {
    Optional<SocialAccount> findByPublicId(UUID publicId);

    // 소셜 로그인 시 기존 회원 찾기
    Optional<SocialAccount> findByProviderAndProviderUserId(Provider provider, String providerUserId);

    // 특정 유저의 특정 소셜 계정 삭제 (연동 해제)
    void deleteByUserAndProvider(User user, Provider provider);
}
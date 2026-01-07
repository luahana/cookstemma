package com.pairingplanet.pairing_planet.repository.user;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Long> {
    // API 조회용 (UUID)
    Optional<User> findByPublicId(UUID publicId);

    // 로그인/가입용
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
}
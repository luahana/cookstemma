package com.pairingplanet.pairing_planet.support;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.Role;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class TestUserFactory {

    @Autowired
    private UserRepository userRepository;

    public User createTestUser() {
        return createTestUser("testuser_" + UUID.randomUUID().toString().substring(0, 8));
    }

    public User createTestUser(String username) {
        User user = User.builder()
                .username(username)
                .email(username + "@test.com")
                .locale("ko-KR")
                .role(Role.USER)
                .status(AccountStatus.ACTIVE)
                .build();
        return userRepository.save(user);
    }

    public User createAdminUser() {
        User user = User.builder()
                .username("admin_" + UUID.randomUUID().toString().substring(0, 8))
                .email("admin_" + UUID.randomUUID().toString().substring(0, 8) + "@test.com")
                .locale("ko-KR")
                .role(Role.ADMIN)
                .status(AccountStatus.ACTIVE)
                .build();
        return userRepository.save(user);
    }
}

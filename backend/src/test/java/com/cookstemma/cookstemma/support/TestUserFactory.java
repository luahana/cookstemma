package com.cookstemma.cookstemma.support;

import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.repository.user.UserRepository;
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
        return createTestUser(username, "ko-KR");
    }

    public User createTestUser(String username, String locale) {
        User user = User.builder()
                .username(username)
                .email(username + "@test.com")
                .locale(locale)
                .role(Role.USER)
                .status(AccountStatus.ACTIVE)
                .build();
        return userRepository.saveAndFlush(user);
    }

    public User createAdminUser() {
        User user = User.builder()
                .username("admin_" + UUID.randomUUID().toString().substring(0, 8))
                .email("admin_" + UUID.randomUUID().toString().substring(0, 8) + "@test.com")
                .locale("ko-KR")
                .role(Role.ADMIN)
                .status(AccountStatus.ACTIVE)
                .build();
        return userRepository.saveAndFlush(user);
    }

    public User createBotUser(String username, BotPersona persona) {
        User user = User.builder()
                .username(username)
                .locale(persona.getLocale())
                .defaultCookingStyle(persona.getCookingStyle())
                .role(Role.BOT)
                .status(AccountStatus.ACTIVE)
                .isBot(true)
                .persona(persona)
                .build();
        return userRepository.saveAndFlush(user);
    }
}

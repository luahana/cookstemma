package com.pairingplanet.pairing_planet.support;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.Role;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.test.context.support.WithSecurityContextFactory;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

public class WithMockCustomUserSecurityContextFactory
        implements WithSecurityContextFactory<WithMockCustomUser> {

    @Override
    public SecurityContext createSecurityContext(WithMockCustomUser annotation) {
        SecurityContext context = SecurityContextHolder.createEmptyContext();

        User user = User.builder()
                .username(annotation.username())
                .email(annotation.username() + "@test.com")
                .locale("ko-KR")
                .role(Role.valueOf(annotation.role()))
                .status(AccountStatus.ACTIVE)
                .build();

        // Set id and publicId using reflection since they are auto-generated
        ReflectionTestUtils.setField(user, "id", annotation.id());
        ReflectionTestUtils.setField(user, "publicId", UUID.fromString(annotation.publicId()));

        UserPrincipal principal = new UserPrincipal(user);
        Authentication auth = new UsernamePasswordAuthenticationToken(
                principal, null, principal.getAuthorities());
        context.setAuthentication(auth);

        return context;
    }
}

package com.pairingplanet.pairing_planet.support;

import org.springframework.security.test.context.support.WithSecurityContext;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

@Retention(RetentionPolicy.RUNTIME)
@WithSecurityContext(factory = WithMockCustomUserSecurityContextFactory.class)
public @interface WithMockCustomUser {
    long id() default 1L;
    String publicId() default "550e8400-e29b-41d4-a716-446655440000";
    String username() default "testuser";
    String role() default "USER";
}

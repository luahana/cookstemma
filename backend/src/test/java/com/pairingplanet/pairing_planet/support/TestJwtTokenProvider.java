package com.pairingplanet.pairing_planet.support;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class TestJwtTokenProvider {

    // Same secret as in application-test.yml
    private static final String TEST_SECRET = "dGVzdC1zZWNyZXQta2V5LWZvci1wYWlyaW5nLXBsYW5ldC1hcHBsaWNhdGlvbi10ZXN0aW5n";
    private static final long ACCESS_TOKEN_VALIDITY = 1000L * 60 * 30; // 30 minutes
    private static final long REFRESH_TOKEN_VALIDITY = 1000L * 60 * 60 * 24 * 14; // 14 days

    private final SecretKey key;

    public TestJwtTokenProvider() {
        this.key = Keys.hmacShaKeyFor(TEST_SECRET.getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(UUID publicId, String role) {
        return Jwts.builder()
                .subject(publicId.toString())
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + ACCESS_TOKEN_VALIDITY))
                .signWith(key)
                .compact();
    }

    public String createRefreshToken(UUID publicId) {
        return Jwts.builder()
                .subject(publicId.toString())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + REFRESH_TOKEN_VALIDITY))
                .signWith(key)
                .compact();
    }

    public String createExpiredToken(UUID publicId) {
        return Jwts.builder()
                .subject(publicId.toString())
                .issuedAt(new Date(System.currentTimeMillis() - 100000))
                .expiration(new Date(System.currentTimeMillis() - 50000))
                .signWith(key)
                .compact();
    }
}

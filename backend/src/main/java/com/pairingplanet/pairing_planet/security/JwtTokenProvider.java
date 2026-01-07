package com.pairingplanet.pairing_planet.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {
    private final SecretKey key;
    private final long ACCESS_TOKEN_VALIDITY = 1000L * 60 * 30; // 30분
    private final long REFRESH_TOKEN_VALIDITY = 1000L * 60 * 60 * 24 * 14; // 14일

    public JwtTokenProvider(@Value("${jwt.secret}") String secret) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(UUID publicId, String role) {
        return createToken(publicId, role, ACCESS_TOKEN_VALIDITY);
    }

    public String createRefreshToken(UUID publicId) {
        return createToken(publicId, null, REFRESH_TOKEN_VALIDITY);
    }

    private String createToken(UUID publicId, String role, long validity) {
        JwtBuilder builder = Jwts.builder()
                .subject(publicId.toString())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + validity))
                .signWith(key);
        if (role != null) builder.claim("role", role);
        return builder.compact();
    }

    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    public String getSubject(String token) {
        return parseClaims(token).getPayload().getSubject();
    }

    public String getRole(String token) {
        return parseClaims(token).getPayload().get("role", String.class);
    }

    private Jws<Claims> parseClaims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
    }
}
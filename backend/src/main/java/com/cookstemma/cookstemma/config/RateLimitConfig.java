package com.cookstemma.cookstemma.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.BucketConfiguration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Configuration for rate limiting using Bucket4j.
 * Defines rate limit configurations for different endpoints.
 */
@Configuration
public class RateLimitConfig {

    @Value("${app.rate-limit.enabled:true}")
    private boolean enabled;

    @Value("${app.rate-limit.auth.requests-per-minute:5}")
    private int authRequestsPerMinute;

    @Value("${app.rate-limit.reissue.requests-per-minute:10}")
    private int reissueRequestsPerMinute;

    @Value("${app.rate-limit.bot-login.requests-per-minute:20}")
    private int botLoginRequestsPerMinute;

    @Value("${app.rate-limit.content.requests-per-minute:30}")
    private int contentRequestsPerMinute;

    @Value("${app.rate-limit.upload.requests-per-minute:20}")
    private int uploadRequestsPerMinute;

    /**
     * Cache for storing bucket configurations per endpoint pattern.
     */
    @Bean
    public Map<String, BucketConfiguration> rateLimitConfigurations() {
        Map<String, BucketConfiguration> configs = new ConcurrentHashMap<>();

        // Rate limit for login endpoints: 5 requests per minute
        configs.put("/api/v1/auth/social-login", createBucketConfig(authRequestsPerMinute, Duration.ofMinutes(1)));
        configs.put("/api/v1/auth/web/social-login", createBucketConfig(authRequestsPerMinute, Duration.ofMinutes(1)));

        // Rate limit for token reissue: 10 requests per minute
        configs.put("/api/v1/auth/reissue", createBucketConfig(reissueRequestsPerMinute, Duration.ofMinutes(1)));
        configs.put("/api/v1/auth/web/reissue", createBucketConfig(reissueRequestsPerMinute, Duration.ofMinutes(1)));

        // Rate limit for logout: 10 requests per minute
        configs.put("/api/v1/auth/web/logout", createBucketConfig(reissueRequestsPerMinute, Duration.ofMinutes(1)));

        // Rate limit for bot login: 20 requests per minute (higher limit for automated systems)
        configs.put("/api/v1/auth/bot-login", createBucketConfig(botLoginRequestsPerMinute, Duration.ofMinutes(1)));

        // Rate limit for content creation: 30 requests per minute
        configs.put("/api/v1/recipes", createBucketConfig(contentRequestsPerMinute, Duration.ofMinutes(1)));
        configs.put("/api/v1/log_posts", createBucketConfig(contentRequestsPerMinute, Duration.ofMinutes(1)));

        // Rate limit for image upload: 20 requests per minute (resource intensive)
        configs.put("/api/v1/images/upload", createBucketConfig(uploadRequestsPerMinute, Duration.ofMinutes(1)));

        return configs;
    }

    @Bean
    public boolean rateLimitEnabled() {
        return enabled;
    }

    private BucketConfiguration createBucketConfig(int capacity, Duration refillPeriod) {
        return BucketConfiguration.builder()
                .addLimit(Bandwidth.builder()
                        .capacity(capacity)
                        .refillGreedy(capacity, refillPeriod)
                        .build())
                .build();
    }
}

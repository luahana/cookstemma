package com.cookstemma.cookstemma.config;

import com.cookstemma.cookstemma.filter.IdempotencyFilter;
import com.cookstemma.cookstemma.filter.RateLimitFilter;
import com.cookstemma.cookstemma.filter.SentryUserFilter;
import com.cookstemma.cookstemma.security.CsrfTokenFilter;
import com.cookstemma.cookstemma.security.JwtAuthenticationEntryPoint;
import com.cookstemma.cookstemma.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final IdempotencyFilter idempotencyFilter;
    private final RateLimitFilter rateLimitFilter;
    private final CsrfTokenFilter csrfTokenFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    // Optional: Only injected when Sentry DSN is configured
    @Autowired(required = false)
    private SentryUserFilter sentryUserFilter;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList(
            "http://localhost:3000",
            "http://localhost:3001",
            "https://dev.cookstemma.com",
            "https://staging.cookstemma.com",
            "https://cookstemma.com",
            "https://www.cookstemma.com",
            "https://cookstemma.com",
            "https://www.cookstemma.com",
            "https://staging.cookstemma.com"
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())

                // 2. HTTP 기본 인증 및 폼 로그인 비활성화 (필요 시)
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // Enable anonymous authentication for guest access
                .anonymous(anonymous -> {})
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint(jwtAuthenticationEntryPoint) // 401 처리
                )
                .authorizeHttpRequests(auth -> auth
                        // Public endpoints (no auth required) - must come before wildcard rules
                        .requestMatchers("/actuator/health").permitAll()
                        .requestMatchers("/api/v1/bot/personas", "/api/v1/bot/personas/").permitAll()  // Bot personas - public
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/**").permitAll()  // Explicit POST for auth
                        .requestMatchers("/api/v1/auth/**").permitAll()
                        .requestMatchers("/api/v1/contexts/**").permitAll()
                        .requestMatchers("/api/v1/autocomplete/**").permitAll()
                        .requestMatchers("/api/v1/home/**").permitAll()
                        .requestMatchers("/api/v1/search/**").permitAll()
                        .requestMatchers("/share/**").permitAll()

                        // Protected user-specific endpoints (must come before wildcard rules)
                        .requestMatchers("/api/v1/users/me", "/api/v1/users/me/**").authenticated()
                        .requestMatchers("/api/v1/recipes/my").authenticated()
                        .requestMatchers("/api/v1/recipes/saved").authenticated()

                        // Protected write operations (POST, PUT, PATCH, DELETE)
                        .requestMatchers(HttpMethod.POST, "/api/v1/**").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/api/v1/**").authenticated()
                        .requestMatchers(HttpMethod.PATCH, "/api/v1/**").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/**").authenticated()

                        // Guest access: Allow anonymous read (GET) for browsing
                        .requestMatchers("/api/v1/recipes", "/api/v1/recipes/**").permitAll()
                        .requestMatchers("/api/v1/log_posts", "/api/v1/log_posts/**").permitAll()
                        .requestMatchers("/api/v1/users/**").permitAll()
                        .requestMatchers("/api/v1/hashtags/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/comments/**").permitAll()

                        // Protected endpoints (auth required)
                        .requestMatchers("/api/v1/images/**").authenticated()

                        .anyRequest().authenticated()
                )
                // Filter chain order:
                // 1. RateLimitFilter - Rate limiting (before auth to prevent brute force)
                // 2. JwtAuthenticationFilter - JWT token validation
                // 3. SentryUserFilter - Capture user context for error tracking (optional)
                // 4. CsrfTokenFilter - CSRF validation for cookie-based auth
                // 5. IdempotencyFilter - Idempotency key handling
                .addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(csrfTokenFilter, JwtAuthenticationFilter.class)
                .addFilterAfter(idempotencyFilter, CsrfTokenFilter.class);

        // Add Sentry user filter if configured (production/staging only)
        if (sentryUserFilter != null) {
            http.addFilterAfter(sentryUserFilter, JwtAuthenticationFilter.class);
        }

        return http.build();
    }
}
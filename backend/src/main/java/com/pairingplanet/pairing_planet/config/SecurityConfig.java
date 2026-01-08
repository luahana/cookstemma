package com.pairingplanet.pairing_planet.config;

import com.pairingplanet.pairing_planet.filter.IdempotencyFilter;
import com.pairingplanet.pairing_planet.security.JwtAuthenticationEntryPoint;
import com.pairingplanet.pairing_planet.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final IdempotencyFilter idempotencyFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
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
                        // Public endpoints (no auth required)
                        .requestMatchers("/api/v1/auth/**").permitAll()
                        .requestMatchers("/api/v1/contexts/**").permitAll()
                        .requestMatchers("/api/v1/autocomplete/**").permitAll()
                        .requestMatchers("/api/v1/home/**").permitAll()
                        .requestMatchers("/share/**").permitAll()

                        // Protected user-specific endpoints (must come before wildcard rules)
                        .requestMatchers("/api/v1/users/me").authenticated()
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

                        // Protected endpoints (auth required)
                        .requestMatchers("/api/v1/images/**").authenticated()

                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(idempotencyFilter, JwtAuthenticationFilter.class);

        return http.build();
    }
}
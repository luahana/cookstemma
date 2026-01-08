package com.pairingplanet.pairing_planet.config;

import com.pairingplanet.pairing_planet.filter.IdempotencyFilter;
import com.pairingplanet.pairing_planet.security.JwtAuthenticationEntryPoint;
import com.pairingplanet.pairing_planet.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
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
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint(jwtAuthenticationEntryPoint) // 401 처리
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/auth/**").permitAll() // [중요] reissue 포함 인증 API는 전체 허용
                        .requestMatchers("/api/v1/contexts/**").permitAll()
                        .requestMatchers("/api/v1/autocomplete/**").permitAll()
                        .requestMatchers("/api/v1/home/**").permitAll() // 홈 피드는 공개
                        .requestMatchers("/share/**").permitAll() // 소셜 공유 Open Graph (크롤러 접근용)

                        .requestMatchers("/api/v1/images/**").authenticated()
                        .requestMatchers("/api/v1/users/**").authenticated()

                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(idempotencyFilter, JwtAuthenticationFilter.class);

        return http.build();
    }
}
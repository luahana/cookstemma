package com.pairingplanet.pairing_planet.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.dto.Auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.Auth.SocialLoginRequestDto;
import com.pairingplanet.pairing_planet.security.JwtTokenProvider;
import com.pairingplanet.pairing_planet.service.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false) // Security Filter 비활성화 (단순 Controller 로직만 테스트)
class AuthControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired
    ObjectMapper objectMapper;

    @MockitoBean
    AuthService authService;
    @MockitoBean
    JwtTokenProvider jwtTokenProvider; // SecurityConfig 로딩을 위해 필요

    @Test
    @DisplayName("소셜 로그인 성공 시 토큰을 반환한다")
    void socialLogin_Success() throws Exception {
        // given
        SocialLoginRequestDto request = new SocialLoginRequestDto(
                "GOOGLE", "sub-123", "email@test.com", "user", null, "token", null
        );

        AuthResponseDto response = new AuthResponseDto(
                "access-jwt", "refresh-jwt", UUID.randomUUID(), "user"
        );

        given(authService.socialLogin(any(SocialLoginRequestDto.class))).willReturn(response);

        // when & then
        mockMvc.perform(post("/api/v1/auth/social-login")
                        .with(csrf()) // WebMvcTest에선 CSRF가 켜질 수 있으므로 더미 토큰 추가
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("access-jwt"))
                .andExpect(jsonPath("$.username").value("user"));
    }

    @Test
    @DisplayName("필수 파라미터(provider) 누락 시 400 에러를 반환한다")
    void socialLogin_ValidationFail() throws Exception {
        // given
        SocialLoginRequestDto invalidRequest = new SocialLoginRequestDto(
                "", // Provider Empty
                "sub-123", "email", "user", null, "token", null
        );

        // when & then
        mockMvc.perform(post("/api/v1/auth/social-login")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }
}
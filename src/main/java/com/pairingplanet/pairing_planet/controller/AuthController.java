package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.Auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.Auth.SocialLoginRequestDto;
import com.pairingplanet.pairing_planet.dto.Auth.TokenReissueRequestDto;
import com.pairingplanet.pairing_planet.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // 로그인 (가입 포함)
    @PostMapping("/social-login")
    public ResponseEntity<AuthResponseDto> socialLogin(@RequestBody @Valid SocialLoginRequestDto request) {
        return ResponseEntity.ok(authService.socialLogin(request));
    }

    // 토큰 갱신 (Sliding Expiration + RTR)
    @PostMapping("/reissue")
    public ResponseEntity<AuthResponseDto> reissue(@RequestBody @Valid TokenReissueRequestDto request) {
        return ResponseEntity.ok(authService.reissue(request));
    }
}
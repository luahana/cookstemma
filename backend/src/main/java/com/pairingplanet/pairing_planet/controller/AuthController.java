package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.auth.AuthResponseDto;
import com.pairingplanet.pairing_planet.dto.auth.SocialLoginRequestDto;
import com.pairingplanet.pairing_planet.dto.auth.TokenReissueRequestDto;
import com.pairingplanet.pairing_planet.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

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

    // 기존의 firebase-login 엔드포인트는 삭제 가능

    @PostMapping("/reissue")
    public ResponseEntity<AuthResponseDto> reissue(@RequestBody @Valid TokenReissueRequestDto request) {
        return ResponseEntity.ok(authService.reissue(request));
    }
}
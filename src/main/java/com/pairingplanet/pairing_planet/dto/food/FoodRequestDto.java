package com.pairingplanet.pairing_planet.dto.food;

public record FoodRequestDto(
        Long id,
        String name,
        String localeCode // 신규 음식일 경우 필요
) {}